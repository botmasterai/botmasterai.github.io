---
date: 2016-11-17T18:16:51Z
next: /tutorials
prev: /working-with-botmaster/middleware
title: Writing your Own Bot Class
toc: true
weight: 30
---

## Bot classes

The following document assumes that you have read the main documentation in "getting started" and in "botmaster basics". A general understand of how Botmaster and more generally how chatbots work is also assumed.

Because of that, we will pick up right from there and start looking into the bot classes Botmaster comes bundled with.

Botmaster makes five usable bot classes available to developers out of the box. `MessengerBot`, `SlackBot`, `SocketioBot`, `TelegramBot` and `TwitterBot`.

For example, you can instantiate a new `MessengerBot` object as such:

```js
const Botmaster = require('botmaster');
const MessengerBot = Botmaster.botTypes.MessengerBot;

const messengerSettings = {
  credentials: {
    verifyToken: 'YOUR verifyToken',
    pageToken: 'YOUR pageToken',
    fbAppSecret: 'YOUR fbAppSecret'
  },
  webhookEndpoint: '/webhook1234',
};

const messengerBot = new MessengerBot(messengerSettings);
```

In order to get updates from Messenger, you would then be expected to mount your bot's express mini-app `messengerBot.app` onto your own express `app` by doing something like this:

```js
const app = require('express')();
app.use('/', messengerBot.app);
app.listen(3001, function() {});
```

Or even better:

```js
messengerBot.app.listen(3001, function() {});
```

This will mount your bot onto: `https://Your_Domain_Name:3001/webhook1234`. Note how the bot type **is not** part of the URL here.

## Making Botmaster objects and bot objects work together

Doing this is really trivial and as it turns out, you do this every time you use the `addBot` method.

We recall from the various guides that to create a botmaster object the following is needed:

```js
const Botmaster = require('botmaster');
const botmaster = new Botmaster();
```


As usual, we create a botmaster object. This one supports Twitter and Telegram, but not Messenger. We create it as such:


In this example the `botmaster` object will start a new `express()` `app` server running locally on port `3000` as expected by default (see [here](/working-with-botmaster/botmaster-basics/#using-botmaster-with-your-own-express-app) to see how to change that).

As usual, we add the messenegrBot as follows:

```js
botmaster.addBot(messengerBot);
```

This will mount your bot onto: `https://Your_Domain_Name:3000/messenger/webhook1234`. Note how the bot type **is** part of the endpoint here. This is because the Botmaster class assumes that you want your endpoint to be mounted onto its botType.

You will then get updates from the botmaster object as if you had instantiated it with the messenger settings too if your endpoint is setup properly.

{{% notice info %}}
Please note, if you followed these steps and put all this code in one file. You will actually have two express servers running along side each other. One on port 3001 and one on port 3000. Both endpoints mentioned above would work. This is definitely not what you want to do in production. Pick one of the methods and stick to it in production.
{{% /notice %}}


**The main takeaway from all this is that any bot class that follows a  certain set of rules will be able to be added to a botmaster object.**


## Creating your own bot classes

Before defining the rules that have to be respected in order to write a Botmaster compatible bot class let's look at the constructor of one of the existing one, `TelegramBot`:

### `#constructor(settings)`

```js
class TelegramBot extends BaseBot {

  constructor(settings) {
    super(settings);
    this.type = 'telegram';
    this.requiresWebhook = true;
    this.requiredCredentials = ['authToken'];

    this.__applySettings(settings);
    .
    .
    .
    this.__createMountPoints();
  }

 }
```

Let's look into this line by line. The first line reads `super(settings)`. Which of course just means it calls the constructor of `TelegramBot`'s superclass, namely, `BaseBot`. `BaseBot`'s constructor doesn't actually do anything fancy a part from calling its own superclass's constructor and setting a few default values [as pointers for you, the developer]. BaseBot calls its own superclass's constructor as it inherits from node.js's `EventEmitter` which will allow your bot's classes to listen to events as well as emit them.

The following three lines setup some important values.

  1. `this.type`: the type of bot that is being instantiated. It's important to specify that as developers might want to condition some code on the type of bot you are writing.
  2. `this.requiresWebhook`: whether the bot requires webhooks. If the platform you are coding for requires webhooks, you will be expected to set a `this.app` variable at some point in the setup. We'll look into this when we have a look at what the `this.__createMountPoints();` does.
  3. `this.requiredCredentials`: sets up an array of credentials that are expected to be defined for the platform you are coding your class for. Telegram only takes in 1, so we just have an array with the value `'authToken'`.

### `#__applySettings(settings)`

The next line calls the `this.__applySettings(settings)` function. This function is implemented in BaseBot and will just make sure that the settings passed on to the bot constructor are valid with respect to the parameters you defined. You should always call this function directly after setting the three [or more or less depending on your bot] parameters specific to the platform you are coding for. If valid, the settings will then be applied to the bot object. e.g. `this.webhookEndpoint` will be set to `settings.webhookEndpoint`.

### `#__createMountPoints()`

The last line of our controller makes a call to `this.__createMountPoints();`. This line should only be present if your bot class requires webhooks. If this is the case, you will be expected to define a class member function that looks something like:

```js
  __createMountPoints() {
    this.app = express();
    // for parsing application/json
    this.app.use(bodyParser.json());
    // for parsing application/x-www-form-urlencoded
    this.app.use(bodyParser.urlencoded({ extended: true }));

    this.app.post(this.webhookEndpoint, (req, res) => {
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

Very importantly, this function creates an express router `this.app` that will be mounted onto the main `app` router from the botmaster object if `botmaster.addBot` is used.

It then sets up the post endpoint that listens onto `this.webhookEnpoint`. No further assumption is made here.

Please note that you might have another function that needs to be called at this point. For instance, in the `socketioBot` class, I make a call to: `this.__setupSocketioServer();` and that function looks like this:

```js
__setupSocketioServer() {
  this.ioServer = io(this.server);

  this.ioServer.on('connection', (socket) => {
    socket.join(SocketioBot.__getBotmasteruserId(socket));

    socket.on('message', (message) => {
      // just broadcast the message to other connected clients with same user id
      const botmasterUserId = SocketioBot.__getBotmasteruserId(socket);
      socket.broadcast.to(botmasterUserId).emit('own message', message);
      // console.log(JSON.stringify(socket.rooms, null, 2));
      const rawUpdate = message;
      try {
        rawUpdate.socket = socket;
      } catch (err) {
        err.message = `ERROR: "Expected JSON object but got '${typeof message}' ${message} instead"`;
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

Like `__applySettings`, this method is implemented in `BaseBot`. It handles errors, calling the `incoming` middleware stack, and most importantly, actually calling `this.emit(update)` to emit the actual update. You can overwrite this method if you wish, but in its current state, it handles the most important cases you will want to deal with. You should call this method with the formatted `update` object created by calling `formatUpdate()`;

### `#__sendMessage(message)`

All previous methods had either something to do with object instantiation or with incoming messages. We'll now have a look at what needs to be done within your bot class to send messages.

The `__sendMessage` method needs to be implemented. The method should take in a Messenger style message and send a formatted message to the bot platform. It should return a `Promise` that resolves to something like this:

```js
  {
   raw: rawBody,
   recipient_id: <id_of_user>,
   message_id: <message_id_of_what_was_just_sent>
  }
 ```

 Code for it might look like this simplified one from `TelegramBot`:

 ```js
 __sendMessage(message) {
  const options = {
    url: 'https://api.telegram.org/sendMessage',
    method: 'POST',
  };
  options.json = this.__formatOutgoingMessage(message);

  return request(options) // using request-promise package and not request here

  .then((body) => {
    if (body.error) {
      throw new Error(JSON.stringify(body.error));
    }

    const standardizedBody = {
      raw: body,
      recipient_id: body.result.chat.id,
      // this is really the equivalent to a Messenger seq.
      // But it's either that or null for telegram
      message_id: body.result.message_id,
    };
    return standardizedBody;
  });
}
 ```

See how we are returning a promise that resolves to an object as specified above!

It is important to note that this be a promise and not a callback. Although developers using Botmaster can use `sendMessage` type methods with callbacks. The internals of Botmaster use Promises and therefore, so should your bot class.

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

### `#__formatOutgoingMessage(message)`

Your `sendMessage` method is expected to call a `__formatOutgoingMessage(message)` method that will format the Messenger style message into one that is compatible with the platform you are coding your bot class for.

You can have a look at the ones defined in the `TelegramBot` and the `TwitterBot` classes for inspiration.

### `#__setBotIdIfNotSet(update)`

In order to help you identify between bots of different types, you will want each bot instance to have a `this.id` value. This should typically be the same as `update.recipient.id` when getting updates. If these aren't set upon instantiation (as with Facebook Messenger bots), you can write a function like this `MessengerBot` one that gets called upon receiving a message.

```js
__setBotIdIfNotSet(update) {
  if (!this.id) {
  	this.id = update.recipient.id;
  }
}
```

## Is this really all there is to it?

Yes it is! These few basic steps are the steps that should be followed in order to build your own bot classes. Nothing more is required. Of course, formatting the incoming updates and the outgoing messages won't always be as trivial as we'd wish, but this guide should help you into doing this.
