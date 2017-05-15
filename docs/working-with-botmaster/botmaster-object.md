# Botmaster object

### Settings

Botmaster can be started with a so-called `botmasterSettings` object. It has the following parameters:
The `botmasterSettings` object has the following parameters:

| Parameter | Description
|--- |---
| port  | (__optional__) The port to use for your webhooks (see [webhooks](/getting-started/webhooks.md) to understand more about webhooks). This will only be used if the `server` parameter is not provided. Otherwise, it will be ignored.
| server  | (__optional__) A valid node http server app object to mount the `webhookEndpoints` onto. If you choose to do this, it is assumed that you will be managing your own server instance (possibly via express of Koa or other). Thus, Botmaster won't start the server.

Using botsSettings would look something like this if you want to set the port:

```js
const botmasterSettings = require('botmaster');

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

>Please note, unless you are passing in a `server` object to the settings, it is assumed that you don't want to deal with anything relating to an http server. That is, botmaster will create an express server under the hood and expose `botmaster.server` back.

#### Example 1: Using Botmaster with your own express app

Here's an example on how to do so if you are setting your credentials in your environment variables:

```js
const Botmaster = require('botmaster');
const express = require('express');

const app = express();
const port = 3000;
const myServer = app.listen(port, '0.0.0.0');
const botmaster = new Botmaster({ server: myServer });

myServer.on('listening', () => {
  console.log('My express app is listening and its server is used in Botmaster');
})
```

#### Example 2: Using Botmaster with your own Koa app

Here's an example on how to do so if you are setting your credentials in your environment variables:

```js
const Botmaster = require('botmaster');
const Koa = require('koa');

const app = new Koa();
const port = 3000;
const myServer = app.listen(port, '0.0.0.0');
const botmaster = new Botmaster({ server: myServer });

myServer.on('listening', () => {
  console.log('My Koa app is listening and its server is used in Botmaster too');
})
```

### Events

Botmaster is built on top of the EventEmitter node.js class. Which means it can emit events and most importantly for us here, it can listen onto them. By doing any of the following:

```js
botmaster.on('listening', (message) => {
  console.log(message);
});

botmaster.on('error', (bot, err) => {
  console.log(bot.type);
  console.log(err.stack);
});
```

These are the only two listeners that you can listen onto in botmaster. Let's go though them briefly:

#### server running

This event will be emitted only if you are not managing your own server (i.e. you started botmaster without setting the `app` parameter). It is just here to notify you that the server has been started. You don't necessarily need to use it. But you might want to do things at this point.

#### error

This event is thrown whenever an error internal to Botmaster occurs. I.e. if for some reason a mis-configured message was sent in. Or if some other kind of error occurred directly within Botmaster. It is good to listen onto this event and keep track of potential errors. Also, if you code an error within your incoming middleware, and don't catch it, it will be caught by Botmaster and emitted in to `error`. So like this you have full control of what is going on and can log everything straight from there.
