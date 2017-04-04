# Messaging Platforms

Botmaster v3 is very minimal. This means it comes with the support for no messaging platform out of the box.
Support for platforms has to be added via external packages.

## Official Bot classes

1. [Messenger](https://github.com/botmasterai/botmaster-messenger)
2. [Slack](https://github.com/botmasterai/botmaster-slack)
3. [Socket.io](https://github.com/botmasterai/botmaster-socket.io)
4. [Telegram](https://github.com/botmasterai/botmaster-telegram)
5. [Twitter DM](https://github.com/botmasterai/botmaster-twitter-dm)

## Installing

It looks something like this to install them:

```bash
yarn add botmaster-messenger
```

or

```bash
npm install --save botmaster-messenger
```

## Using a botmaster-botClass package

These "messaging platforms" come in the the form of Bot Classes in Botmaster semantic. and they can the be used in code like such:

```js
const botmaster = require('botmaster');
const MessengerBot = require('messenger-bot');
const config = require('./config'); // where I keep my credentials

const messengerBot = newMessengerBot({
  credentials: config.messengerCredentials,
  webhookEndpoint: 'webhook',
})

botmaster.addBot(messengerBot);
```