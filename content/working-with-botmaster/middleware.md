---
date: 2017-01-16T16:56:06Z
next: /working-with-botmaster/writing-your-own-bot-class
prev: /working-with-botmaster/botmaster-basics
title: Middleware
toc: true
weight: 20
---

## Middleware basics

Middleware in Botmaster is designed to work similarly to  what you would expect in an express.js app. However, you might not have used express and they work slightly differently, so here's a writeup of how they work.

Generally, middleware allows developers to do some preprocessing on some received data before performing some main action based on what was received (like sending a response to the client that made the request). Because the term pre-processing is fairly vague and can be interpreted as broad, developers often end up having the main parts of their code within middleware. Botmaster is no different.

Because Botmaster is a chatbot framework and not a we app framework, we go on and define two different types of middleware: `incoming` and `outgoing` middleware. Incoming middleware is akin to what you would have in a standard express middleware (if you have experience with express), whereas outgoing middleware will act on your response object.

Here is the signature of `botmaster.use`

| Parameter | Description
|--- |---
| middlewareType  | either `'incoming'` or `'outgoing'` depending on what middleware you are setting up.
| options | (__optional__) set options for when to activate the middleware. Currently only supports a `type` parameter that takes in a space separated string of platform names (names are defined in the bot classes and values are set in `bot.type`)
| middlewareCallback | The actual middleware function that will be called. It is of type: `function(bot, update, next)` on `incoming` and `function(bot, message, next)` on `outgoing`

### Incoming middleware

As mentioned briefly above, `incoming` middleware in Botmaster is similar to what you would have in express middleware and can be used similarly. They are all called in order of declaration upon receiving a message before entering the `on('update'...)` function. Here is a very simple example of how one would go on and use `incoming` middleware:

```js
botmaster.use('incoming', (bot, update, next) => {
  // assumed here that some weather API is queried to get that weatherInformation
  update.weatherInformation = {
    weather: 23,
    unit: 'celcius',
  }
  next(); // !! always call next when done to go to next middleware function
});

botmaster.on('update', (bot, update) => {
  if (update.weatherInformation.weather > 20) {
    bot.reply(update, 'the weather is warm');
  } else {
    bot.reply(update, 'the weather is mild');
  }
});
```

This is a very basic example. But hopefully, it gets the message through of how and why you would use `incoming` middleware. Clearly, anything can be done in a middleware function, like calling external APIs etc. You are encouraged to do so really.

Now if I wanted to, say, have a middleware function that would get hit after the first one and only on Facebook Messenger bots (bots of type `messenger`), I would do so as follows:

```js
.
.
  next(); // !! always call next when done to go to next middleware function
});

// this middleware function is called after the one setting weatherInformation
// so `update.weatherInformation` exists here
botmaster.use('incoming', { type: 'messenger' }, (bot, update, next) => {
  update.user = bot.getUserInfo(update.sender.id)

  .then((userInfo) => {
    update.userInfo = userInfo;
    next(); // next is here called after the
  });
});

// just set update.username
botmaster.use('incoming', (bot, update, next) => {
  update.username = 'there';

  if (update.userInfo) {
    update.username = update.userInfo.first_name;
  }
  next();
});

botmaster.on('update', (bot, update) => {
  if (update.weatherInformation.weather > 20) {
    bot.reply(update, `Hi ${update.username}, the weather is warm`);
  } else {
    bot.reply(update, `Hi ${update.username}, the weather is warm`);
  }
});
```

In this example, I expand on the previous example and setup two new middleware functions. One that will be called only on bots of type `messenger` and the other one on all bots. The first one gets the information available on the user if the bot is of type messenger. The second one then set the `update.username` according to whether it finds a name or not. As mentioned, they are called in order.

Now that we've had a look at incoming middleware, let's have a look at how outgoing middleware works.

### Outgoing middleware
