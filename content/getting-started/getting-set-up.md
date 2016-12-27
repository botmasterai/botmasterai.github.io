---
date: 2016-10-31T22:33:42Z
next: /getting-started/messenger-setup
prev: /getting-started/quickstart
title: Getting set up
toc: true
weight: 30
---

The following will create a `botmaster` object you will be using in the rest of your code:

```js
const Botmaster = require('botmaster');
const botmaster = new Botmaster();
```

You would then add support for various messaging platforms as follows:

```js
const somePlatformBot = new PlatformBot(platformBotSettings);
botmaster.addBot(somePlatformBot);
```

In practice this would look something like this for, say, Facebook Messenger:

```js
const messengerSettings = {
  credentials: {
    verifyToken: 'YOUR verifyToken',
    pageToken: 'YOUR pageToken',
    fbAppSecret: 'YOUR fbAppSecret',
  },
  webhookEndpoint: '/webhook1234', // botmaster will mount this webhook on https://Your_Domain_Name/messenger/webhook1234
};
const messengerBot = new Botmaster.botTypes.MessengerBot(messengerSettings);
botmaster.addBot(messengerBot);
```

Where you'd typically hold the settings in a `config` file somewhere.
In order to instantiate a `Botmaster` object, you need to pass it some settings in the form of an object. These settings look like this. See the various getting started guides for the different platforms to see both what credentials are required and how to gather them.



### botmasterSettings
You might want/need to specify the port to start botmaster on, or more generally, the express app that it should be working on (in this case you would have specified your own port separately)

```js
const botmasterSettings = {
  app: app, // optional, an express app object if you are running your own express server
  port: port, // optional, only used if "app" is not defined. Defaults to 3000 in that case
  botsSettings: botsSettings, // optional see below for a definition of botsSettings [deprecated. Use 'botmaster.addBot()' instead]
  server: server, // optional, an http server object (used only if using socket.io) [deprecated. add server directly to socketioSettings]
}
```
See [Working with Botmaster](/working-with-botmaster) for a more formal definition

Once you have those `botmasterSettings`, you would instantiate a `Botmaster` object as such:

```js
const botmaster = new Botmaster(botmasterSettings);
```
