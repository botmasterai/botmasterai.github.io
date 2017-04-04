# Botmaster object

### Settings

Botmaster can be started with a so-called `botmasterSettings` object. It has the following parameters:
The `botmasterSettings` object has the following parameters:

| Parameter | Description
|--- |---
| port  | (__optional__) The port to use for your webhooks (see [webhooks](#webhooks) to understand more about webhooks). This will only be used if the `app` parameter is not provided. Otherwise, it will be ignored
| app  | (__optional__) An `express.js` app object to mount the `webhookEnpoints` onto. If you choose to do this, it is assumed that you will be starting your own express server and this won't be done by Botmaster. Unless you also specify a `server` parameter, `botmaster.server` will be `undefined`

>`botsSettings` and `server` parameters have been deprecated in version 2.2.3. Please use `addBot` instead of botsSettings and set the socketio server in your socketSettings object.

Using botsSettings would look something like this if you want to set the port:

```js
const Botmaster = require('botmaster');

const botmasterSettings = {
  // by default botmaster will start an express server that listens on port 3000
  // you can pass in a port argument here to change this default setting:
  port: 3001
}

const botmaster = new Botmaster(botmasterSettings);

.
. // rest of code adding bots to botmaster etc
.

```

>Please note, unless you are passing in an `app` object to the settings, it is assumed that you don't want to deal with anything relating to an http server. That is, botmaster will create an express server under the hood and expose both: `botmaster.app` and `botmaster.server`.

#### Setting `botmasterSettings` to use Botmaster with your own express() app

Here's an example on how to do so if you are setting your credentials in your environment variables:

```js
const express = require('express');
const Botmaster = require('botmaster');

const app = express();
const port = 3000;
const botmasterSettings = { app: app };
const botmaster = new Botmaster(botmasterSettings);

// settings and adding those to botmaster
const telegramSettings = {
  credentials: {
    authToken: process.env.TELEGRAM_TOKEN,
  },
  webhookEndpoint: '/webhook1234/',
};

const messengerSettings = {
  credentials: {
    verifyToken: process.env.MESSENGER_VERIFY_TOKEN,
    pageToken: process.env.MESSENGER_PAGE_TOKEN,
    fbAppSecret: process.env.FACEBOOK_APP_SECRET,
  },
  webhookEndpoint: '/webhook1234/',
};

const messengerBot = new Botmaster.botTypes.MessengerBot(messengerSettings);
const telegramBot = new Botmaster.botTypes.TelegramBot(telegramSettings);

botmaster.addBot(messengerBot);
botmaster.addBot(telegramBot);
////////

botmaster.on('update', (bot, update) => {
  bot.sendMessage({
    recipient: {
      id: update.sender.id,
    },
    message: {
      text: 'Well right back at you!',
    },
  });
});

// start server on the specified port and binding host
app.listen(port, '0.0.0.0', () => {
  // print a message when the server starts listening
  console.log(`Running App on port: ${port}`);
});
```

#### Setting `botmasterSettings` to use Botmaster with your own express() app and own server object

This example is what you should base your code on if you are using socket.io and your own http server object rather than the default botmaster one.

Here's an example on how to do so if you are setting your credentials in your environment variables:

```js
const http = require('http');
const express = require('express');
const Botmaster = require('botmaster');

const app = express();
const myServer = http.createServer(app);
const port = 3000;
const botmasterSettings = { app: app };
const botmaster = new Botmaster(botmasterSettings);

// settings and adding those to botmaster
const telegramSettings = {
  credentials: {
    authToken: process.env.TELEGRAM_TOKEN,
  },
  webhookEndpoint: '/webhook1234/',
};

const socketioSettings = {
  id: 'SOME_ID',
  server: myServer,
};

const telegramBot = new Botmaster.botTypes.TelegramBot(telegramSettings);
const socketioBot = new Botmaster.botTypes.SocketioBot(socketioSettings);


botmaster.addBot(messengerBot);
botmaster.addBot(socketioBot);
////////

botmaster.on('update', (bot, update) => {
  bot.sendMessage({
    recipient: {
      id: update.sender.id,
    },
    message: {
      text: 'Well right back at you!',
    },
  });
});

// start server on the specified port and binding host
myServer.listen(port, '0.0.0.0', () => {
  // print a message when the server starts listening
  console.log(`Running App on port: ${port}`);
});
```

The difference between this example and the previous one is that in the previous, we are using the express helper `app.listen` which essentially wraps around the `http` `server.listen` and returns a server instance. Whereas here we are doing it all ourselves and use `myServer.listen`.

### Events

Botmaster is built on top of the EventEmitter node.js class. Which means it can emit events and most importantly for us here, it can listen onto them. By doing any of the following:

```js
botmaster.on('server running', (message) => {
  console.log(message);
});

botmaster.on('update', (bot, update) => {
  console.log(bot.type);
  console.log(update);
});

botmaster.on('error', (bot, err) => {
  console.log(bot.type);
  console.log(err.stack);
});
```

These are the only four listeners that you can listen onto in botmaster. Let's go though them briefly:

#### server running

This event will be emitted only if you are not managing your own server (i.e. you started botmaster without setting the `app` parameter). It is just here to notify you that the server has been started. You don't necessarily need to use it. But you might want to do things at this point.

#### update

This is really where all the magic happens. Whenever a message (update in Botmaster semantic) is sent into your application. Botmaster will parse it and format it into its [FB Messenger] standard. Along with it, you will get a `bot` object which is the underlying object into which the message was sent. Note that the updates are standardized as well as the methods to use from the bot object (i.e. sending a message). Read further down to see how those two objects work.

#### error

This event is thrown whenever an error internal to Botmaster occurs. I.e. if for some reason a misconfigured message was sent in. Or if some other kind of error occurred directly within Botmaster. It is good to listen onto this event and keep track of potential errors. Also, if you code an error within `botmaster.on`, and don't catch it, it will be caught by Botmaster and emitted in to `error`. So like this you have full control of what is going on and can log everything straight from there.
