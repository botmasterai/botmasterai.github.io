---
date: 2017-01-16T16:56:06Z
next: /working-with-botmaster/writing-your-own-bot-class
prev: /working-with-botmaster/botmaster-basics
title: Middleware
toc: true
weight: 20
---

Middleware in Botmaster is designed to work similarly to  what you would expect in an express.js app. However, you might not have used express and they work slightly differently, so here's a writeup of how they work.

Generally, middleware allows developers to do some preprocessing on some received data before performing some main action based on what was received (like sending a response to the client that made the request). Because the term pre-processing is fairly vague and can be interpreted as broad, developers often end up having the main parts of their code within middleware. Botmaster is no different. Here's a typical diagram flow showing how it looks like under the hood.



![Middleware Diagram 1](/images/middleware_diagram.png)


Because Botmaster is a chatbot framework and not a web app framework, we go on and define two different types of middleware: `incoming` and `outgoing` middleware. Incoming middleware is akin to what you would have in a standard express middleware (if you have experience with express), whereas outgoing middleware will act on your response object.

Here is the signature of `botmaster.use`

| Parameter | Description
|--- |---
| middlewareType  | either `'incoming'` or `'outgoing'` depending on what middleware you are setting up.
| options | (__optional__) set options for when to activate the middleware. Currently only supports a `type` parameter that takes in a space separated string of platform names (names are defined in the bot classes and values are set in `bot.type`)
| middlewareCallback | The actual middleware function that will be called. It is of type: `function(bot, update, next)` on `incoming` and `function(bot, message, next)` on `outgoing`

## Incoming middleware

As mentioned briefly above, `incoming` middleware in Botmaster is similar to what you would have in express middleware and can be used similarly. They are all called in order of declaration upon receiving an update before entering the `on('update'...)` function.

### Basic incoming middleware example

Here is a very simple example of how one would go on and use `incoming` middleware:

```js
botmaster.use('incoming', (bot, update, next) => {
  // assumed here that some weather API is queried to get that weatherInformation
  update.weatherInfo = {
    weather: 23,
    unit: 'celcius',
  }
  next(); // !! always call next when done to go to next middleware function
});

botmaster.on('update', (bot, update) => {
  if (update.weatherInfo.weather > 20) {
    bot.reply(update, 'the weather is warm');
  } else {
    bot.reply(update, 'the weather is mild');
  }
});
```

This is a very basic example. But hopefully, it gets the message through of how and why you would use `incoming` middleware. Clearly, anything can be done in a middleware function, like calling external APIs etc. You are encouraged to do so really.

### Basic incoming middleware example with structure

In practice, your middleware code will really live within separate files that you would "require" within your main "app.js" file. That means that the previous example will have a tree structure similar to the following:

```
├── app.js
└── middleware
    ├── incoming
    │   ├── weather.js
    │   └── index.js
    └── outgoing // no outgoing middleware in this example
        └── index.js // this will remain an empty file for now
```

This is only a suggested structure (the one I use). Feel free to come up with a different, potentially better, structure that suits you better.

That means that the previous example's code will probably look more like this:

`middleware/incoming/weather.js`

```js
// using eslint disallowFunctionDeclarations here. Read here: https://github.com/airbnb/javascript#functions to see why I use this syntax rather than the standard function updateText(bot,  message, next) one.
const addWeatherInfoToUpdate = function addWeatherInfoToUpdate(bot, update, next) {
  update.weatherInfo = {
    weather: 23,
    unit: 'celcius',
  }
  next();
}

module.exports = {
  addWeatherInfoToUpdate, // using shorthand here
}
```

`middleware/incoming/index.js`
```js
const weather = require('./weather');

module.exports = {
  weather,
};
```

`app.js`

```js
const incomingMiddleware = require('./middleware/incoming');

botmaster.use('incoming', incomingMiddleware.weather.addWeatherInfoToUpdate);

botmaster.on('update', function(bot, update){
  if (update.weatherInformation.weather > 20) {
    bot.reply(update, 'the weather is warm');
  } else {
    bot.reply(update, 'the weather is mild');
  }
});
```

### Complete incoming middleware example with structure

Now if I wanted to, say, add a couple of user info related middleware functions including a middleware function that would get hit only on Facebook Messenger bots (bots of type `messenger`), using the same base structure, and updating it as follows:

```
├── app.js
└── middleware
    ├── incoming
    │   ├── weather.js
    │   ├── user_info.js
    │   └── index.js
    └── outgoing
        └── index.js
```

I would do the following:

create the file `middleware/incoming/user_info.js` as follows:

`middleware/incoming/user_info.js`

```js
const addUserInfoToUpdate = function addUserInfoToUpdate(bot, update, next) {
  bot.getUserInfo(update.sender.id)

  .then((userInfo) => {
    update.userInfo = userInfo;
    next(); // next is only called once the user information is gathered
  });
}

const addUsernameToUpdate = function addUsernameToUpdate(bot, update, next) {
  update.username = 'there';

  if (update.userInfo) {
    update.username = update.userInfo.first_name;
  }
  next();
}

module.exports = {
  addUserInfoToUpdate,
}
```

Then update `middleware/incoming/index.js` and `app.js` to look like this respectively:

`middleware/incoming/index.js`

```js
const weather = require('./weather');
const userInfo = require('./user_info');

module.exports = {
  weather,
  userInfo,
};
```

`app.js`

```js
const incomingMiddleware = require('./middleware/incoming');

botmaster.use('incoming', incomingMiddleware.weather.addWeatherInfoToUpdate);
botmaster.use('incoming', { type: 'messenger' },
              incomingMiddleware.userInfo.addUserInfoToUpdate);
botmaster.use('incoming', incomingMiddleware.userInfo.addUsernameToUpdate);

botmaster.on('update', (bot, update) => {
  if (update.weatherInformation.weather > 20) {
    bot.reply(update, `Hi ${update.username}, the weather is warm`);
  } else {
    bot.reply(update, `Hi ${update.username}, the weather is warm`);
  }
});
```

In this example, I expand on the previous example and setup two new middleware functions. One that will be called only on bots of type `messenger` and the other one on all bots. The first one gets the information available on the user if the bot is of type `messenger`. The second one then sets the `update.username` according to whether it finds a name or not. As mentioned, they are called in order of declaration.

It should be clear by now that this reads much clearer than the previous example. Simply by reading the `app.js` file I can have an idea of what is going on in the code. Cleary, some weather information and user information is added to the `update` object that information is then used to customize the text returned to the user.

Now that we've had a look at incoming middleware, let's have a look at how outgoing middleware works.

## Outgoing middleware

similar to the `incoming` middleware, the `outgoing` middleware is called in order of declaration. However, it is called on every message object sent by you the developer. To illustrate this, here's an example:

### Basic example

```js
botmaster.on('update', function(bot, update){
  bot.reply(update, 'Hello world!') // using a helper function to send text message
});

botmaster.use('outgoing', function(bot, message, next) {
  console.log(message); // this is a full valid messenger object.

  message.message.text = "Hello you!";
  next();
});
```

In this example, the first three lines are what you would expect if you were simply trying to reply "Hello world" to any message. However, if you try this out, you'll see that you get a "Hello you!" text message back. Indeed, our middleware, aside from printing the message object to show you what it looks like, replaces the text with "Hello you".

This is really what you'll want to be doing within outgoing middleware. First use one of the Botmaster helper functions to send a message, then edit it in your outgoing middleware functions. Botmaster simply creates the valid [messenger compatible] message object before hitting the outgoing middleware where you can play with this.

### Basic example with structure

As in the incoming middleware example, in practice, your middleware code will really live within separate files that you would "require: within your main "app.js" file. Using a structure similar to the one used in the incoming middleware example. We look at something like this:

```
├── app.js
└── middleware
    ├── incoming // no incoming middleware in this example
    │   └── index.js // this will remain an empty file for now
    └── outgoing
        ├── message_transformers.js
        └── index.js
```

Where your code will look something like this
That means that the previous example will probably look more like this:

`middleware/outgoing/message_transformers.js`

```js
// using eslint disallowFunctionDeclarations here. Read here: https://github.com/airbnb/javascript#functions to see why I use this syntax rather than the standard function updateText(bot,  message, next) one.
const changeText = function changeText(bot, message, next) { // using
  console.log(message); // this is a full valid messenger object.

  message.message.text = 'Hello you!';
  next();
}

module.exports = {
  changeText, // using shorthand here
}
```

`middleware/outgoing/index.js`
```js
const messageTransformers = require('./message_transformers');

module.exports = {
  messageTransformers,
};
```

`app.js`

```js
const outgoingMiddleware = require('./middleware/outgoing');

botmaster.on('update', function(bot, update){
  bot.reply(update, 'Hello world!') // using a helper function to send text message
});

botmaster.use('outgoing', outgoingMiddleware.messageTransformers.updateText);
```

This might seem like slight overkill at this point because of how trivial of an example this is. But this adds clear structure to our project and when reading our app.js file we can already know what is going on. It also makes it very clear regarding what is going on if you were to add another middleware function right after the `updateText` one.

### Complete outgoing middleware example with structure

Taking this one step further, you can do something like the following to, say, send buttons without using the builtin `sendDefaultButtonMessageTo` method. We'll keep our structure and simply update the files to look like this:

`middleware/outgoing/message_transformers.js`
```js
const changeText = function changeText(bot, message, next) { // using
  console.log(message);

  if (message.message.text === 'Thank you') {
    message.message.text = 'Thanks';
  }

  next();
}

const addButtonsToMessage = function addButtonsToMessage(bot, message, next) {
  const text = message.message.text;

  const buttonsRegexObject = text.match(/&\[.+]/);
  if (buttonsRegexObject) {
    const buttonTitles = JSON.parse(buttonsRegexObject[0].substring(1));
    const cleanedText = text.replace(buttonsRegexObject[0], '');

    message.message.quick_replies = [];
    for (const buttonTitle of buttonTitles) {
      message.message.quick_replies.push({
        content_type: 'text',
        title: buttonTitle,
        payload: buttonTitle,
      });
    }

    message.message.text = cleanedText;
  }

  next();
}

module.exports = {
  changeText, // using shorthand here
  addButtonsToMessage,
}
```

This simple `addButtonsToMessage` function simply uses regular expressions to see if the text contains any bit of text that looks anything like the following: `'["Button1","Button2"]'`. If any such string is found, it then proceeds to add a quick_replies component to your message object and update the text to remove those button mentions. We next have a look at `app.js` that also has to be transformed:

`app.js`

```js
const outgoingMiddleware = require('./middleware/outgoing');

botmaster.on('update', function(bot, update){
  bot.sendTextCascadeTo(['Hi there, I`m about to ask you to press buttons:',
                         'Please press any of: ["Button1","Button2"]',
                         'Thank you']);
});

botmaster.use('outgoing', outgoingMiddleware.messageTransformers.updateText);
botmaster.use('outgoing', outgoingMiddleware.messageTransformers.addButtonsToMessage);
```

Now this will work great. But actually, what i want to do is show the user a typing indicator right before sending every message that goes out. Because I'm using a sendCascade function, namely, `sendTextCascadeTo`, the best way to do so is to do this within an outgoing middleware function. Here's how we can edit `app.js` to achieve this goal:

`app.js`

```js
const outgoingMiddleware = require('./middleware/outgoing');

botmaster.on('update', function(bot, update){
  bot.sendTextCascadeTo(['Hi there, I`m about to ask you to press buttons:',
                         'Please press any of: ["Button1","Button2"]',
                         'Thank you']);
});

botmaster.use('outgoing', outgoingMiddleware.messageTransformers.updateText);
botmaster.use('outgoing', outgoingMiddleware.messageTransformers.addButtonsToMessage);
botmaster.use('outgoing', (bot, update, next) => {
  const userId = message.recipient.id;

  bot.sendIsTypingMessageTo(userId, { ignoreMiddleware: true })

  .then(() => {
    setTimeout(() => {
      next();
    }, 1000);
  });
})
```

There's a few things going on in this added bit of code here. First we make it clear again that middleware code can technically live anywhere. It would be better to have it in a separate file somewhere. But this also works. Second, We introduce the `ignoreMiddleware` option when sending a message. This will always work and simply tells Botmaster to not go through any of the middleware with this message and send it directly. This is very important as otherwise, we would be stuck in an infinite loop trying to send an "is typing" indicator. Second we note that we use `setTimeout` to make it look like the bot is typing for about 1 second before firing out the message by calling `next()`.

## External middleware

This is all great. But Using the code in `addButtonsToMessage` to add buttons to your message is probably not the best. Indeed, external middleware packages provide better solutions to this problem. Like in any other framework that contains middleware, middleware can be put into packages. These packages are then available and downloadable via `npm` and thus easily accessible in your code.

Have a look in our list of official middleware [here](/middlewares/official-middleware)
