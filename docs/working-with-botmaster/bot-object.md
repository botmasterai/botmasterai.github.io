# Bot object

This guide is meant to be read after going through the [quickstart](/getting-sarted/quickstart.md).
We remember from the [quickstart](/getting-started/quickstart) that we can start a botmaster project like this:


```js
const Botmaster = require('botmaster');
const MessengerBot = require('botmaster-messenger');
const SlackBot = require('botmaster-slack');
const SocketIoBot = require('botmaster-socket.io');
const TwitterDmBot = require('botmaster-twitter-dm');
const TelegramBot = require('botmaster-telegram');

const botmaster = new Botmaster();
.
. // full settings objects omitted for brevity
.
const messengerBot = new MessengerBot(messengerSettings);
botmaster.addBot(messengerBot);
botmaster.addBot(new SlackBot(slackSettings));
botmaster.addBot(new SocketioBot(socketioSettings)));
botmaster.addBot(new TwitterBDmot(twitterSettings));
botmaster.addBot(new TelegramBot(telegramSettings));

.
.
.
```
That is, assuming we have added the necessary packages to our dependencies. Installing them either via `yarn add` or via `npm install --save`

As it turns out, bot objects are really the ones running most of the show in the Botmaster framework (alongside middleware). Your `botmaster` object is simply a central point of control for you to manage all of your bots. Bot classes are built on top of the Botmaster `BaseBot` class that exposes all the actions one will want to take using Botmaster.

Bot objects allow you perform all sorts of actions. These actions go along the line of sending messages to users on the platform, getting info on a certain user (if platform supports that) and creating OutgoingMessages. See the api reference for [BaseBot](/api-reference/base-bot.md) to see all the methods that can be used.

As much as you could just start shooting out messages right after creating a bot object (e.g. from our `messengerBot` object in the previous example), you'll typically be using bot objects within middleware. Without diving deep into middleware, we'll show how bot objects are used (similar to what we did in the [quickstart](/gettings-started/quickstart.md))

Let's first note here, that you can have multiple bot objects for a certain type. I'm sure you can find reasons for why you would want to do this. This is important to mention, as you might have, say, 2 bots of type `messenger` dealt with via Botmaster. You might want to do platform specific code by doing the following:

```js
botmaster.use({
  type: 'incoming',
  name: 'some-middleware',
  controller: (bot, update) => {
    if (bot.type === 'messenger') {
      // do messenger specific stuff like:
      return bot.reply(update, 'you are using our bot on messenger');
    })

    return bot.reply(update, 'you are not using our bot on messenger');
  }
});
```

Then you might want to do bot object specific code. You would do this as such:

```js
botmaster.use({
  type: 'incoming',
  name: 'some-middleware',
  controller: (bot, update, next) => {
    if (bot.type === 'messenger') {
      // do messenger specific stuff
      if (bot.id === 'YOUR_BOT_ID') {
        // this will be e.g. the user id of your bot for messenger
        // which is the newest of two bots that do similar stuff
        return bot.reply(update, 'you are using the new version bot on messenger');
      }
      return bot.reply(update, 'you are using the old version bot on messenger');
    })
  }
});
```

Or if you declared your bots and botmaster as in the beginning of this section, you might have done the following:

```js
const Botmaster = require('botmaster');
const MessengerBot = require('botmaster-messenger');
const SlackBot = require('botmaster-slack');
const TwitterDmBot = require('botmaster-twitter-dm');

const botmaster = new Botmaster();

.
. // full settings objects omitted for brevity
.
const messengerBot1 = new MessengerBot(messengerSettings1);
const messengerBot2 = new MessengerBot(messengerSettings2);
const slackBot = new SlackBot(slackSettings);
const twitterBot = new TwitterBot(twitterSettings);

botmaster.addBot(messengerBot1);
botmaster.addBot(messengerBot2);
botmaster.addBot(slackBot);
botmaster.addBot(twitterBot);

botmaster.use({
  type: 'incoming',
  name: 'some-middleware',
  controller: (bot, update, next) => {
    if (bot.type === 'messenger') {
      // do messenger specific stuff
      if (bot === messengerBot1) {
        return bot.reply(update, 'you are using the new version bot on messenger');
      }
      return bot.reply(update, 'you are using the old version bot on messenger');
    })
  }
});
```

>Botmaster does not assure you that the `id` parameter of the `bot` object will exist upon instantiation. the `id` is only assured to be there once an update has been received by the bot. I.e. in all middleware functions This is because some ids aren't known until botmaster knows 'who' the message was sent to (i.e. what id your bot should have).

I'll note quickly that each bot object created comes from one of the various bot classes as seen above. They act in the same way on the surface (because of heavy standardization), but have a few idiosynchrasies here and there.

Many of those idiosynchrasies can be found out by leveraging the following in your bot objects: `bot.receives`, `bot.sends` and `bot.retrievesUserInfo`. These objects look as such:

##### 1. **bot.receives**:
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

##### 2. **bot.sends**:
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

##### 3. **bot.retrievesUserInfo**:
```js
this.retrievesUserInfo = false;
```

Where each of these values is true if the bot class implements them. All official bot classes will expose these elements to you so you can leverage those in your middleware.

Some bot classes (like the one provided by the `botmaster-messenger` package) can expose methods that are only available for this specific bot type. These methods will always be prepended with an underscore. E.g. `botmaster-messenger` exposes: `_setGetStartedButton` which allow you to set up a get started button only in FB messenger.

Also useful to note is that you can access all the bots added to botmaster by doing `botmaster.bots`. you can also use `botmastet.getBot` or `botmaster.getBots` to get a specific bot (using type or id);

It is important to take note of the `addBot` syntax as you can create your own Bot class that extends the `Botmaster.botTypes.BaseBot` class. For instance, you might want to create your own class that supports your pre-existing messaging standards. Have a look at the [writing your own bot class](/working-with-botmaster/writing-your-own-bot-class.md) documentation to learn how to do this.