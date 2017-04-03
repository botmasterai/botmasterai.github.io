# Messaging Platforms

Botmaster v3 is very minimal. This means it comes with the support for no messaging platform out of the box.
Support for platforms has to be added via external packages. It looks something like this to install them:

```bash
yarn add botmaster-messenger
```

or

```bash
npm install --save botmaster-messenger
```

These "messaging platforms" come in the the form of Bot Classes in Botmaster semantic. and they can the be used in code like such:

```js
const botmaster = require('botmaster');
const MessengerBot = require('messenger-bot');
const config = require('./config'); // where I keep my credentials

const messengerBot = newMessengerBot({
  credentials: config.messengerCredentials,
  webhookEndpoint: 'webhook',
})

botmaster.add(messengerBot);
```

### Official Bot classes

1. [Messenger](messenger.md)
2. [Slack](/slack.md)
3. [Socket.io](socket.io.md)
4. [Telegram](telegram.md)
5. [Twitter DM](twitter-dm.md)
