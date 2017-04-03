[![LOGO](/images/botmaster_light.svg)](http://botmasterai.com)

## Botmaster v3 is here

Please note, this is the documentation for Botmaster v3 (3.0.7 and above).
To read the documentation for Botmaster v2, please change the version to 2.3.1 in the left pane.

Want to migrate from version 2.x.x to version 3? Have a look at the 3.0.7 changelog that doubles as a migration documentation:
[here](changelog.md#major-307)

## What is Botmaster?

Botmaster is a lightweight highly extendable, highly configurable chatbot framework. It was meant to be used both in small scale and large scale projects. Its purpose is to integrate your chatbot into a variety of messaging channels - currently packages have been written for Facebook Messenger, Slack, Twitter DM, Telegram and socket.io. Using botmaster will look something like this in code:

```js
const Botmaster = require('botmaster');
const MessengerBot = require('botmaster-messenger');
const SlackBot = require('botmaster-slack');
const SocketIoBot = require('botmaster-socket.io');
const TwitterBot = require('botmaster-twitter-dm');
const TelegramBot = require('botmaster-telegram');

const config = require('./config'); // your config file with your credentials etc

const botmaster = new Botmaster();

botmaster.addBot(new MessengerBot(config.messengerSettings));
botmaster.addBot(new SlackBot(config.slackSettings));
botmaster.addBot(new SocketioBot({
  id: 'mySocket.ioId', // whatever you want it to be for socket.io bots
}));
botmaster.addBot(new TwitterBot(config.twitterSettings));
botmaster.addBot(new TelegramBot(config.telegramSettings));

botmaster.use({
  type: 'incoming',
  name: 'Update replier', // this is optional, but should ideally describe what your middleware does
  controller: (bot, update) => {
    return bot.reply(update, 'Right back at you!');
  }
});
```

## Botmaster is platform agnostic

Botmaster is platform agnostic in two important ways. Firstly, out of the box, developers can have bots running on Facebook Messenger, Slack, Twitter DM, Telegram and their personal webapp/app via socket.io with not only a standardized text message format, but also a standardized attachment format. Secondly, BotMaster makes no assumptions about the back-end bot itself - you can write code that allows BotMaster to call conversational engines such as IBM Watson's conversation API, open source frameworks or even write the conversation engine yourself.

## Botmaster's Philosophy

Its philosophy is to minimize the amount of code developers have to write in order to create 1-on-1 conversational chatbots that work on multiple platforms. It does so by defining a standard with respect to what format messages take and how 1-on-1 conversations occur. Messages to/from the various messaging channels supported are all mapped onto this botmaster standard, meaning the code you write is much reduced when compared to a set of point:point integrations.
