# Changelog

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
