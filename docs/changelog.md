# Changelog

### MAJOR 3.0.8

Botmaster v3 is almost a complete rewrite of botmaster. Although much of the philosophy is the same, a lot of breaking changes have been introduced. Surely, you will find that they are for the better. This changelog doubles as a migration help.

##### 1. Upgrading to botmastser v3

You most likely have a line that looks like this in your package.json:

```json
  "dependencies": {
    "botmaster": "^2.x.x",
  }
```

In order to change that, either do a 

```bash
yarn upgrade botmaster
```
if using yarn

or:

```bash
npm install --save botmaster@3
```
if using npm

This will change that line in your dependencies to something like:

```json
  "dependencies": {
    "botmaster": "^3.0.8",
  }
```

Or newer if newer versions were released recently.

##### 2. Bot classes now have their own packages

Firstly, all the bot classes have been taken out and put in their own packages. This means if you want to write a bot that only works on, say, socket.io and Messenger, you don't actually have the code for the other bot classes anymore. You would need to do something like this:

```bash
yarn add botmaster
yarn add botmaster-messenger
yarn add botmaster-socket.io
```

or if still using npm

```bash
npm install --save botmaster
npm install --save botmaster-messenger
npm install --save botmaster-socket.io
```

then in your code:

```js
const Botmaster = require('botmaster');
const MessengerBot = require('botmaster-messenger');
const SocketioBot = require('botmaster-socket.io');
.
.
.
// then rest of code
```

The other bot classes that were available in 2.x.x can be found at:
`botmaster-slack`
`botmaster-telegram`
`botmaster-twitter-dm`

##### 3. Botmaster is not built on top of express anymore

First of all, this is only important for you to note if you were using your own express app and not
letting Botmaster create it for you. If that isn't your case, you won't need to change anything here.

In order to make Botmaster really flexible, moving away from a dependency on express was important.
This means that you can now either just let botmaster create its own server as it used to do via express in 2.x.x.
Or, you can completely manage your own server (using express, koa, plain http or other).

This means that doing this will now throw an error:

```js
// DON'T DO THIS ANYMORE!!!
const Botmaster = require('botmaster');
const express = require('express');

const app = express();
const botmaster = new Botmaster({ app });

app.listen(3000, '0.0.0.0', () => { // remember this creates an http server under the hood
  console.log('My express app is listening and its server is used in Botmaster');
})
```

Instead, if you want to manage your own app object, you will need to do something like this
```js
// DO THIS INSTEAD!!
const Botmaster = require('botmaster');
const express = require('express');

const app = express();
const myServer = app.listen(3000, '0.0.0.0');
const botmaster = new Botmaster({ server: myServer });

myServer.on('listening', () => {
  console.log('My express app is listening and its server is used in Botmaster');
})
```

Now, this might look like nothing much has changed, but here's why this is an important change. If instead of
having an express app, you have a Koa app (or other), this will essentially still work as all that Botmaster now asks of you
is an instance of http server.

```js
// DO THIS TO USE KOA!!
const Botmaster = require('botmaster');
const Koa = require('koa');

const app = new Koa();
const myServer = app.listen(3000, '0.0.0.0');
const botmaster = new Botmaster({ server: myServer });

myServer.on('listening', () => {
  console.log('My Koa app is listening and its server is used in Botmaster too');
})
```

This was not possible in Botmaster 2.x.x.

##### 4. Middleware

The biggest changes have been made with respect to middleware. Although your middleware functions will still work, they will need to be moved into a slightly new syntax.

Where you had something like this in 2.x.x:

```js
botmaster.use('incoming', (bot, update, next) => {
  // your stuff
});
```

You will now have something like this in 3.x.x:

```js
botmaster.use({
  type: 'incoming',
  name: 'some name of your choosing', // this is optional, but nice for debugging
  controller: (bot, update, next) => {
    // your stuff
  }
});
```

Essentially, the callback has been moved to a controller within an object that describes the middleware in general.
You'll need to do the same thing for your outgoing middleware.

This is what needs to be changed. However, the core of middleware has changes quite a bit. Middleware can now either use the old syntax using next (as it used to in 2.x.x). Or it can leverage newer syntax by returning a promise. I.e. this is now valid middleware

```js
botmaster.use({
  type: 'incoming',
  controller: (bot, update) => {
    return bot.reply(update, 'Hey there')
    .then((body) => {
      // this is run after the message is sent. I.e. also after all the outgoing middleware has been executed
    })
  }
});
```

This means that you can now write your code in a very synchronous looking manner if using node 7+ and running node
with the `--harmony-async-await` flag or simply if you use a transpiler like Babel. Code like this will be valid

```js
botmaster.use({
  type: 'incoming',
  controller: async (bot, update) => {
    const body = await bot.reply(update, 'Hey there')
    // this is run after the message is sent. I.e. also after all the outgoing middleware has been executed
  }
});
```

>If returning a promise, using next within this promise will emit/throw an error depending on if you are in incoming or outgoing middleware. It will emit in incoming middleware and throw in outgoing middleware.

Please note that the returned promise's resolved value (whether you use async-await or not) will not be used
I.e. if in the last example after the `const body = ...` line, you return any value. This will be used nowhere.
Like in the old middleware, you are expected to make changes to the `update` object. Those changes will be available
in the following middleware. All that botmaster assures you with is that the next middleware in the stack will be called
only after the promise from the previous one has resolved. Here's an example using promises:

```js
botmaster.use({
  type: 'incoming',
  name: 'first middleware',
  controller: (bot, update) => {
    return useSomePromiseBasedFunction('something')
    .then((valueFromFunction) => {
      update.value = valueFromFunction;
    })
  }
});

botmaster.use({
  type: 'incoming',
  name: 'second middleware',
  controller: (bot, update, next) => {
    console.log(update.value); // prints valueFromFunction
    next();
  }
});
```

Note how in this example, we are mixing both types of syntax (using promises and next). This is completely fine and even
suggested if, say, your second middleware here is synchronous.

Another addition has been made to middleware. As it turns out, I lied when I said that values resolved by promise-based middleware will be ignored.
There are two cases where they won't be ignored. That's if you return `skip` or `cancel`.

In the previous example, it would look like this:

```js
botmaster.use({
  type: 'incoming',
  name: 'first middleware',
  controller: (bot, update) => {
    return useSomePromiseBasedFunction('something')
    .then((valueFromFunction) => {
      update.value = valueFromFunction;
      return 'skip';
    })
  }
});

botmaster.use({
  type: 'incoming',
  name: 'second middleware',
  controller: (bot, update, next) => {
    // this will never get hit and nothing really will hapen as `first middleware` does not send any message
  }
});
```

`skip` can also be used by outgoing middleware along with `cancel`. Here is an example of using `cancel`:


```js
botmaster.use({
  type: 'incoming',
  name: 'incoming middleware',
  controller: (bot, update) => {
    return bot.reply(update, 'Hey there');
  }
});

botmaster.use({
  type: 'outgoing',
  name: 'first outgoing middleware',
  controller: (bot, update, message) => {
    if (update.message.text === 'Hey there') { // for some arbitrary reason
      return Promise.resolve('cancel');
    }
  }
});

botmaster.use({
  type: 'outgoing',
  name: 'second outgoing middleware',
  controller: (bot, update, message) => {
    // this will not get hit
  }
});
```

In this last example, not only will "second outgoing middleware" not get hit, the message will also not get sent out.
Please note, valid syntax for our "first outgoing middleware are also the following two"

```js
botmaster.use({
  type: 'outgoing',
  name: 'first outgoing middleware',
  controller: async (bot, update, message) => { // if using transpiler or node 7.x with harmony flag
    if (update.message.text === 'Hey there') { // for some arbitrary reason
      return 'cancel';
    }
  }
});
```

and

```js
botmaster.use({
  type: 'outgoing',
  name: 'first outgoing middleware',
  controller: (bot, update, message, next) => {
    if (update.message.text === 'Hey there') { // for some arbitrary reason
      next('cancel');
    }
  }
});
```

Botmaster 3 also add support for using the `useWrapped` method for adding middleware. This method when used
will add an incoming middleware at the beginning of the middleware incoming stack and another outgoing middleware at the end
of the outgoing middeware stack. It'll look something like this:

```js
botmaster.useWrapped(incomingMiddleware, outgoingMiddleware);
```

Where `incomingMiddleware` and `outgoingMiddleware` are valid middlewares of their respective types.
This is useful if writing a middleware package that want to be first to get the update object and last to see it when it goes out.
It is used in `botmaster-session-ware` for instance.

##### 5. `.on('update')` no longer exists.

As it says. You are now expected to move your code that lived in there to an incoming middleware. Should be the last one you declare
so it is run at the end of all your incoming middleware.

##### 6. Bot classes are better defined.

Bot classes now come with 3 new settings that help you know whether you want to execute a middleware or not on an specific update from a bot.
They are:

`bot.receives`. Will look something like this:

```js
this.receives = {
  text: false,
  attachment: {
    audio: false,
    file: false,
    image: false,
    video: false,
    location: false,
    // can occur in FB messenger when user sends a message which only contains a URL
    // most platforms won't support that
    fallback: false,
  },
  echo: false,
  read: false,
  delivery: false,
  postback: false,
  // in FB Messenger, this will exist whenever a user clicks on
  // a quick_reply button. It will contain the payload set by the developer
  // when sending the outgoing message. Bot classes should only set this
  // value to true if the platform they are building for has an equivalent
  // to this.
  quickReply: false,
};
```

`bot.sends`. Will look something like this:

```js
this.sends = {
  text: false,
  quickReply: false,
  locationQuickReply: false,
  senderAction: {
    typingOn: false,
    typingOff: false,
    markSeen: false,
  },
  attachment: {
    audio: false,
    file: false,
    image: false,
    video: false,
  },
};
```

All values will either be falsy or truthy. Ideally, they will even either be `true` or `false`.

And `bot.retrievesUserInfo` which will either be truthy or falsy.

##### 7. OutgoingMessage class has been added

In order to make it easier to compose outgoing messages without having to mess about with the object directly, Botmaster
now sends instances of OutgoingMessage to the outgoing middleware. These objects are just like old message objects in 2.x.x.
(go ahead, you can console log them to see for yourselves), but they just come with a few helper methods to add and remove
stuff from the object. Have a look at the [API reference](/api-reference/outgoing-message.md) for them to see how you can leverage that.

##### 8. SendMessage type methods

There are THREE big changes in the way the sendMessage type methods now work. 

###### 1. You can't use them with callbacks anymore. The only supported way to do anything after the message is sent is to `then` them using promises.

So if you had code like this:

```js
bot.sendMessage(someMessage, (body) => {
  console.log(body);
});
```

you'll need to make it look like this:

```js
bot.sendMessage(someMessage).then((body) => {
  console.log(body);
});
```

This was done because forcing promises means that using async-await syntax will be a breeze with Botmaster.
And async-await is the future. So we didn't want to have you miss on that.

###### 2. You can now use `sendRaw` with all bot classes

Any bot class will have a valid `sendRaw` method (that is just sugar for the underlying Bot class's `__sendMessage` method). This method
allows you to send a message to the platform your bot object is based from without going through any formatting or outgoing middleware.
I.e. it could be used as such:

```js
// within a middleware controller
if (bot.type === 'slack') { // for example
  rawSlackMessage = {
    token: 'someToken',
    channel: 'someChannel',
    as_user: true,
    text: 'someText',
    .
    .
    .
  };

  return bot.sendRaw(rawSlackMessage);
} else {
  return bot.reply(update, 'Thank you for subscribing');
}
```

###### 3. The resolved body from sendMessage type functions now contains much more information. It is now composed of the following:

  * sentOutgoingMessage - the object before going through its formatting
  * sentRawMessage - the sentOutgoinMessage after its formatting
  * raw - the raw response from the platform after sending the obejct
  * recipient_id - the id of the recipient
  * message_id - the id of the sent message (if available)

##### 9. WebhookEndpoint has no initial slash anymore.

When using a bot class that uses webhooks, no need to add a slash at the beginning of the webhookEnpoint paramter.
I.e. if you had something that looked like this:

```js
const messengerSettings = {
  credentials: someCredentials,
  webhookEndpoint: '/webhook1234',
};
```

Change it to:

```js
const messengerSettings = {
  credentials: someCredentials,
  webhookEndpoint: 'webhook1234',
};
```

### MINOR 2.3.0

Outgoing middleware now has access to the incoming update. I.e. outgoing middleware can be used like this:

```js
botmaster.use('outgoing', (bot, update, message, next) => {
  console.log(update);
  console.log(message);
})
```

### PATCH 2.2.7

Add the concept of `implements` for bot classes. Now every bot object has a `bot.implements` object that specifies which functionalities are implemented by the bot class. Currently, the values that exist and can be tested against are:

`quickReply` // for quick replies
`attachment` // does it support attachments
`typing` // does it support typing status

### PATCH 2.2.6

Just fix a bug in outgoing middleware

### PATCH 2.2.5

This patch adds to the body returned when using any of the `bot.sendMessage` type helper methods.

Now the body also contains a `body.sent_message` parameter that is simply the full object that was sent by the bot


### PATCH 2.2.4

This patch allows users to use `sendMessage` type functions with an optional `sendOptions` object. Currently, this can be used to bypass outgoing middleware
when sending messages by using the `ignoreMiddleware` option. Using this looks something like this:

```js
bot.reply(update, 'Hello world!', { ignoreMiddleware: true })
```

or using a callback function

```js
bot.reply(update, 'Hello world!', { ignoreMiddleware: true }, (body) =>
  console.log(body);
);
```

or for buttons

```js
bot.sendDefaultButtonMessageTo(
  ['button1', 'button2'], sender.user.id, 'click on a button',
  { ignoreMiddleware: true })
```

or with cascade messages

```js
bot.sendTextCascadeTo(
  ['message1', 'message2'], sender.user.id,
  { ignoreMiddleware: true }, (bodies) => {

  console.log(bodies);
})
```

### PATCH 2.2.3

This patch adds support for the `bot.sendCascadeTo` and `bot.sendTextCascadeTo` methods. Allowing users to send a cascade of message with just one command rather than having to deal with that themselves. Read more about it here:

[here](/working-with-botmaster/botmaster-basics/#cascade)

### PATCH: 2.2.2

This patch allows users to set the userId from a sender when using the bot socket.io class. socket now needs to be opened with something like this on the client side:

```js
var socket = io('?botmasterUserId=wantedUserId');
```

See updated Botmaster Socket.io bot mini-tutorial [here](/getting-started/socketio-setup/#botmaster-socket-io-bot-mini-tutorial)

### MINOR: Botmaster 2.2.0

This minor release allows developers to create news instances of Botmaster without bots settings by writing something like:

```js
const Botmaster = require('botmaster');
const MessengerBot = Botmaster.botTypes.MessengerBot;
.
.
const botmaster = new Botmaster();
.
. // full settings objects omitted for brevity
.
const messengerBot = new MessengerBot(messengerSettings);
const slackBot = new SlackBot(slackSettings);
const twitterBot = new TwitterBot(twitterSettings);
const socketioBot = new SocketioBot(socketioSettings);
const telegramBot = new TelegramBot(telegramSettings);

botmaster.addBot(messengerBot);
botmaster.addBot(slackBot);
botmaster.addBot(twitterBot);
botmaster.addBot(socketioBot);
botmaster.addBot(telegramBot);
```

This is because it might be viewed as cleaner by some to add bots in the following way rather than doing this in the constructor.

### PATCH: Botmaster 2.1.1

This patch fixes a bug whereby one couldn't instantiate a botmaster object that would use socket.io in all reasonably expected ways. See [here](https://github.com/jdwuarin/botmaster/pull/2) for a discussion.


### MINOR: Botmaster 2.1.0

This version adds support for socket.io bots within the botmaster core. This is the last
bot class that will be in the core

### MAJOR: Botmaster 2.0.0

In this new version, a lot of new things were added to Botmaster. A few others were removed.

#### Breaking Changes
If you were using SessionStore in version 1.x.x, you won't be able to anymore in version 2.x.x. They have been scratched for the far more common middleware design pattern common in so many other frameworks (e.g. express). Middleware can be hooked into right before receiving an update and right before sending out a message. It fits ideally with people wanting to setup session storage at these points.

#### Adding Slack
Support for Slack as the fourth channel supported by Botmaster has been added. Using the Events API, you can now send and receive messages on the platform.

#### get User info
If the platform supports it and the bot class you are using supports it too, you can now use the `bot.getUserInfo` method to retrieve basic information on a user, including their name and profile pic.

#### bug fixes
As with any release, a bunch of bugfixes were done.
