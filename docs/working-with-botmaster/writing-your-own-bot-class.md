# Writing your own bot class

## Bot classes

The following document assumes that you have read the main documentation in "getting started" and in "working with botmaster". A general understand of how Botmaster and more generally how chatbots work is also assumed.

Because of that, we will pick up right from there and start looking into the bot classes we built for 
botmaster.

A few of these bot classes are made available via the following packages:
`botmaster-messenger`, `botmaster-slack`, `botmaster-socket.io`, `botmaster-telegram`, `botmaster-twitter-dm`.

Let's say you added `botmaster-messenger` as a dependency to your project. You'll then be able to do the following:

```js
const Botmaster = require('botmaster');
const MessengerBot = require('botmaster-messenger');

const messengerSettings = {
  credentials: {
    verifyToken: 'YOUR verifyToken',
    pageToken: 'YOUR pageToken',
    fbAppSecret: 'YOUR fbAppSecret'
  },
  webhookEndpoint: 'webhook1234',
};

const messengerBot = new MessengerBot(messengerSettings);
```

In order to get updates from Messenger, you would then be expected to mount your bot's requestListener `messengerBot.requestListener` onto your own server by doing something like this:

```js
server = require('http');
server.createServer(messenger.requestListener);
server.listen(3001, '0.0.0.0');
```
Now if requests come into your server (on any endpoint), your messengerBot object will try to "emit" the update, i.e. run its master's incoming middleware with it. But you guessed correctly if you thought that this would not work. Because `messengerBot` has been added to no botmaster instance, we will get the following error: 'bot needs to be added to a botmaster instance in order to emit received updates'.

Let's make it work then:

## Making Botmaster objects and bot objects work together

Doing this is really trivial and as it turns out, you do this every time you use the `addBot` method.

We recall from the various guides that to create a botmaster object the following is needed:

```js
const Botmaster = require('botmaster');
const botmaster = new Botmaster({
  server, // the server object we created earlier
});
```

As usual, we create a botmaster object. And we make sure that it uses the same server as the one we defined earlier. We then add the messengerBot as follows:

```js
botmaster.addBot(messengerBot);
```

This will mount your bot onto: `https://Your_Domain_Name:3001/messenger/webhook1234`. Note how the bot type **is** part of the endpoint although it is not part of the endpoint. This is because the Botmaster class assumes that you want your endpoint to be mounted onto its botType.

Now when our server receives updates to `https://Your_Domain_Name:3001/messenger/webhook1234`, it will forward it to our incoming middleware. It is important to note that this line: `server.createServer(messenger.requestListener);` will not pose any problem, as botmaster strips all requestlisteners from the server object when instantiated and calls them only if none of the added bot endpoints get hit.

**The main takeaway from all this is that if you are writing a bot class that uses webhooks, all that needs to be exposed is a valid `bot.requestListener` function. We'll see how to do this with express and Koa further down.**

## Creating your own bot classes

Before defining the rules that have to be respected in order to write a Botmaster compatible bot class let's look at the constructor of one of the existing ones. The one from `botmaster-telegram` in this case:

### `#constructor(settings)`

```js
class TelegramBot extends BaseBot {

  constructor(settings) {
    super(settings);
    this.type = 'telegram';
    this.requiresWebhook = true;
    this.requiredCredentials = ['authToken'];

    this.receives = {
      text: true,
      attachment: {
        audio: true,
        file: true,
        image: true,
        video: true,
        location: true,
        fallback: false,
      },
      echo: false,
      read: false,
      delivery: false,
      postback: false,
      quickReply: false,
    };

    this.sends = {
      text: true,
      quickReply: true,
      locationQuickReply: false,
      senderAction: {
        typingOn: true,
        typingOff: false,
        markSeen: false,
      },
      attachment: {
        audio: true,
        file: true,
        image: true,
        video: true,
      },
    };

    this.retrievesUserInfo = false;

    .
    .
    this.id = this.credentials.authToken.split(':')[0];

    this.__applySettings(settings);
    this.__createMountPoints();
  }

 }
```

Let's look into this line by line (or almost). The first line reads `super(settings)`. Which of course just means it calls the constructor of `TelegramBot`'s superclass, namely, `BaseBot`. `BaseBot`'s constructor doesn't actually do anything fancy a part from calling its own superclass's constructor and setting a few default values [as pointers for you, the developer]. BaseBot calls its own superclass's constructor as it inherits from node.js's `EventEmitter` which will allow your bot's classes to listen to events as well as emit them.

The following three lines setup some important values.

  1. `this.type`: the type of bot that is being instantiated. It's important to specify that as developers might want to condition some code on the type of bot you are writing.
  2. `this.requiresWebhook`: whether the bot requires webhooks. If the platform you are coding for requires webhooks, you will be expected to set a `this.app` variable at some point in the setup. We'll look into this when we have a look at what the `this.__createMountPoints();` does.
  3. `this.requiredCredentials`: sets up an array of credentials that are expected to be defined for the platform you are coding your class for. Telegram only takes in 1, so we just have an array with the value `'authToken'`.
  4. `this.receives` An object describing what kind of updates this bot class can receive. I.e. If a platforms supports a certain type, only set a value to true if updates are converted to the FB messenger type for that update type too.
  5. `this.sends` Quite like `this.receives`, just describes what messages can be sent from this bot.
  6. `this.retrievesUserInfo` set to true if the platform/bot class can provide extended information on a user by using the `bot.getUserInfo` method.
  7. `this.id` the id that is proper to the bot. If not set at this point, it should be set upon receiving the first update from the platform


### `#__applySettings(settings)`

The next line calls the `this.__applySettings(settings)` function. This function is implemented in BaseBot and will just make sure that the settings passed on to the bot constructor are valid with respect to the parameters you defined. You should always call this function directly after setting the three [or more or less depending on your bot] parameters specific to the platform you are coding for. If valid, the settings will then be applied to the bot object. e.g. `this.webhookEndpoint` will be set to `settings.webhookEndpoint`.

## Receiving Updates

### `#__createMountPoints()`

The last line of our controller makes a call to `this.__createMountPoints();`. This line should only be present if your bot class requires webhooks. If this is the case, you will be expected to define a class member function that looks something like:

```js
__createMountPoints() {
  this.app = express();
  this.requestListener = this.app;
  // for parsing application/json
  this.app.use(bodyParser.json());
  // for parsing application/x-www-form-urlencoded
  this.app.use(bodyParser.urlencoded({ extended: true }));

  this.app.post('*', (req, res) => {
    this.__formatUpdate(req.body)

    .then((update) => {
      this.__emitUpdate(update);
    }, (err) => {
      err.message = `Error in __formatUpdate "${err.message}". Please report this.`;
      this.emit('error', err);
    });

    // just letting telegram know we got the update
    res.sendStatus(200);
  });
}
```

If we were using Koa in our Bot class, this function would look like this:

```js
__createMountPoints() {
  this.app = new Koa();
  this.requestListener = this.app.callback();

  app.use((ctx) => {
    let bodyString = '';
    ctx.req.on('data', (chunk) => {
      bodyString += chunk;
    });

    ctx.req.on('end', async () => {
      const body = JSON.parse(bodyString);
      try {
        const update = await this.__formatUpdate(req.body)
        this.__emitUpdate(update);
      } catch (err) {
        err.message = `Error in __formatUpdate "${err.message}". Please report this.`;
        this.emit('error', err);
      }
    });

    ctx.status = 200;
  });
}
```

Note how in our express app, we are accepting requests from every route. That's because the botmaster object is responsible to making sure that only requests that are destined for this bot will actually end up hitting that function.

Very importantly, both these functions create a valid `this.requestListener` that will be mounted onto the `botmaster.server` whenever `botmaster.addBot` is used.

### requestListeners

Valid requestListeners are simply functions that could be used when using node http's `createServer` or `listen` functions. I.e. in Node, in general, you could do 

```js
const app = new Koa();
const someServer = http.createServer(app.callback());
someServer.listen(3000, '0.0.0.0');
```

which would be equivalent to:

```js
const app = new Koa();
const someServer = http.createServer();
someServer.listen(3000, '0.0.0.0', app.callback());
```

or

```js
const app = new Koa();
const someServer = app.listen(3000, '0.0.0.0');
```

This is equivalent to doing the same thing with express, using the app object. So here's an example

```js
const app = express();
const someServer = http.createServer(app);
someServer.listen(3000, '0.0.0.0');
```
As the app object in express is a valid requestListener.

### Not using webhooks?

You might have another function that needs to be called at this point. For instance, in the `socketioBot` class, I make a call to: `this.__setupSocketioServer();` and that function looks like this:

```js
__setupSocketioServer() {
  this.ioServer = io(this.server);

  this.ioServer.on('connection', (socket) => {
    debug(`new socket connected with id: ${socket.id}`);
    socket.join(SocketioBot.__getBotmasteruserId(socket));

    socket.on('message', (message) => {
      // just broadcast the message to other connected clients with same user id
      const botmasterUserId = SocketioBot.__getBotmasteruserId(socket);
      socket.broadcast.to(botmasterUserId).emit('own message', message);
      const rawUpdate = message;
      try {
        rawUpdate.socket = socket;
      } catch (err) {
        err.message = `Expected JSON object but got '${typeof message}' ${message} instead`;
        return this.emit('error', err);
      }
      const update = this.__formatUpdate(rawUpdate, botmasterUserId);
      return this.__emitUpdate(update);
    });
  });
}
```

Feel free to have a thorough read at this to understand what is going on here. Because it isn't necessary to understand this in order to build your own bot class, I won't explain what is going on here.

### `#__formatUpdate(rawUpdate)`

Although you can technically handle the body of the request as you wish. In our `__createMountPoints` example here (from TelegramBot code), we make a call to the `__formatUpdate` function with the body of the request.
It would make sense for you to do so for consistency and because it has to be defined if you want your bot class to eventually be referenced in the Botmaster project.

This function is expected to transform the `rawUpdate` into an object which is of the format of Messenger updates, while having an `update.raw` bit that references that `rawUpdate` received.

Typically, it would look something like this for a message with an image attachment. Independent of what platform the message comes from:

```
{
  raw: <platform_specific_raw_update>,
  sender: {
    id: <id_of_sender>
  },
  recipient: {
    id: <id_of_the_recipent> // will typically be the bot's id
  },
  timestamp: <unix_miliseconds_timestamp>,
  message: {
    mid: <message_id>,
    seq: <message_sequence_id>,
    attachments: [
      {
        type: 'image',
        payload: {
          url: 'SOME_IMAGE_URL'
        }
      }
    ]
  }
};
```

Your function should return the update object(or a promise that resolves a formatted update object) in order to then call `__emitUpdate` with it as a parameter.

### `#__emitUpdate(update)`

Like `__applySettings`, this method is implemented in `BaseBot`. It handles errorsa and most importantly calling the `incoming` middleware stack. You can overwrite this method if you wish, but in its current state, it handles the most important cases you will want to deal with. You should call this method with the formatted `update` object created by calling `formatUpdate()`;

## Sending messages

Whenever a message is being sent (i.e. a `sendMessage` helper function is being used), the following methods of your bot class will get hit in order:

1. __formatOutgoingMessage
2. __sendMessage
3. __createStandardBodyResponseComponents

### `#__formatOutgoingMessage(message)`

First, just like for receiving updates, we need to format outgoing messages to the format that will be accepted by the platform we are sending a message to.

This function takes in a valid `OutgoingMessage` as only parameter and returns a formattedOutgoingMessage or RawOutgoingMessage, or a Promise that resolves with that value.

### `#__sendMessage(rawMessage)`

The `__sendMessage` is called right after your __formatOutgoingMessage method and will be passed the formattedOutgoingMessage/rawMessage that was returned by __formatOutgoingMessage.

 Code for it might look like this simplified one from `TelegramBot`:

 ```js
__sendMessage(rawMessage) {
  const endPoint = rawMessage.action
  ? 'sendChatAction'
  : 'sendMessage';

  // this.baseUrl is: 'https://api.telegram.org',
  const url = `${this.baseUrl}/${endPoint}`;

  const options = {
    url,
    method: 'POST',
    json: rawMessage,
  };

  return request(options);
}
```

This method then has to return a promise that resolves with the body response from the platform.

### `#__createStandardBodyResponseComponents`

Lastly, before resolving the promise that first called the `sendMessage` helper function, we want to make sure we can provide them with some sort of standardized components in the body. So this method should return an object that looks like this:

This means we will need to 
```js
  {
   recipient_id: <id_of_user>,
   message_id: <message_id_of_what_was_just_sent>
  }
 ```

 In order to do that, this method gets called like such:

 ```
 __createStandardBodyResponseComponents(sentOutgoingMessage, sentRawMessage, rawBody)
 ```

I.e. everything that has to do with the sent message is available to you.

### BaseBot sendMessage helper functions

Please note that the `BaseBot` superclass defines a set of methods that allow developers to more easily send messages to all platforms without having to build the whole Messenger compatible object themselves. These methods are the following:

`sendMessage`
`sendMessageTo`
`sendTextMessageTo`
`reply`
`sendAttachmentTo`
`sendAttachmentFromURLTo`
`sendDefaultButtonMessageTo`
`sendIsTypingMessageTo`
`sendCascadeTo`
`sendTextCascadeTo`

All these methods will convert a developer specified input into a Facebook Messenger compatible message that will be called as a parameter to `__sendMessage`. That is, they all eventually will call your `__sendMessage` method. You can however overwrite them if need be.

### `#__setBotIdIfNotSet(update)`

In order to help you identify between bots of different types, you will want each bot instance to have a `this.id` value. This should typically be the same as `update.recipient.id` when getting updates. If these aren't set upon instantiation (as with Facebook Messenger bots), you can write a function like this `botamaster-messenger` one that gets called upon receiving a message.

```js
__setBotIdIfNotSet(update) {
  if (!this.id) {
  	this.id = update.recipient.id;
  }
}
```

## Extending bot classes

As you might expect, you can extend any bot class that exists, not just BaseBot for your own purpose. You can also expose any added method by prepending them with a single underscore (which tells developers this function is only available for this botType and not via BaseBot)
