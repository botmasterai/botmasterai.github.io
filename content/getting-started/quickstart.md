---
date: 2016-10-31T21:39:47Z
prev: /getting-started/installation
next: /getting-started/getting-set-up
title: Quickstart
toc: true
weight: 20
---

If you already know your credentials for the platforms you want to be supporting in your project the following code will help you get started

```js

// settings stuff
const Botmaster = require('botmaster');

const botmasterSettings = {
  // by default botmaster will start an express server that listens on port 3000
  // you can pass in a port argument here to change this default setting:
  port: 3001,
}

const botmaster = new Botmaster(botmasterSettings);

// you would typically hold this information in a "config" file.
// or use environment variables
const messengerSettings = {
  credentials: {
    verifyToken: 'YOUR verifyToken',
    pageToken: 'YOUR pageToken',
    fbAppSecret: 'YOUR fbAppSecret',
  },
  webhookEndpoint: '/webhook1234', // botmaster will mount this webhook on https://Your_Domain_Name/messenger/webhook1234
};

const twitterSettings = {
  credentials: {
    consumerKey: 'YOUR consumerKey',
    consumerSecret: 'YOUR consumerSecret',
    accessToken: 'YOUR accessToken',
    accessTokenSecret: 'YOUR accessTokenSecret',
  }
}

const telegramSettings = {
  credentials: {
    authToken: 'YOUR authToken',
  },
  webhookEndpoint: '/webhook1234/',
};

const slackSettings = {
  credentials: {
    clientId: 'YOUR app client ID',
    clientSecret: 'YOUR app client secret',
    verificationToken: 'YOUR app verification Token',
    landingPageURL: 'YOUR landing page URL' // users will be redirected there after adding your bot app to slack. If not set, they will be redirected to their standard slack chats.
  },
  webhookEndpoint: '/webhook',
  storeTeamInfoInFile: true,
};

const socketioSettings = {
  id: 'SOME_ID_OF_YOUR_CHOOSING',
};

// instantiate new objects of the various bot classes bundled in with
// the botmaster package. Other bot class packages can be installed or
// built.
const messengerBot = new Botmaster.botTypes.MessengerBot(messengerSettings);
const slackBot = new Botmaster.botTypes.SlackBot(slackSettings);
const socketioBot = new Botmaster.botTypes.SocketioBot(socketioSettings));
const twitterBot = new Botmaster.botTypes.TwitterBot(twitterSettings);
const telegramBot = new Botmaster.botTypes.TelegramBot(telegramSettings);

botmaster.addBot(messengerBot);
botmaster.addBot(slackBot);
botmaster.addBot(socketioBot);
botmaster.addBot(twitterBot);
botmaster.addBot(telegramBot);

// actual code
botmaster.on('update', (bot, update) => {
  bot.sendTextMessageTo('Right back at you!', update.sender.id);
});

botmaster.on('error', (bot, err) => {
  console.log(err.stack);
  console.log('there was an error');
});
```
