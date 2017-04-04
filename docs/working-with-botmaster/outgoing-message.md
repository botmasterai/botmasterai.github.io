### Outgoing messages

As with incoming updates, in order to achieve standardization, Botmaster's `OutgoingMessage`s  follow the **Facebook Messenger update/message format**.

This means that outgoing messages are expected to be formatted like messages the Messenger platform would expect. They will typically look something like this for a text message:

```js
const message = {
  recipient: {
    id: update.sender.id,
  },
  message: {
    text: 'Some arbitrary text of yours'
  },
}
```

and you would use this as such in code:

```js
botmaster.use({
  type: 'incoming',
  name: 'my-middleware',
  controller: (bot, update) => {
    const message = {
      recipient: {
        id: update.sender.id,
      },
      message: {
        text: 'Some arbitrary text of yours'
      },
    };
    return bot.sendMessage(message);
  }
})
```

To see the available methods we expose via all bot object, such as al the `sendMessage` helper methods, see the [api-reference for BaseBot](/api-reference/base-bot.md)

All these helper methods will end up in creating an instance of `OutgoingMessage` which will then be exposed in your outgoing middleware. For example:

```js
botmaster.use({
  type: 'incoming',
  name: 'my-incoming-middleware',
  controller: (bot, update) => {
    return reply(udpate, 'Hello there');
  }
});

botmaster.use({
  type: 'outgoing',
  name: 'my-outgoing-middleware',
  controller: (bot, update, message) => {
    // message will now be of type OutgoingMessage
    console.log(message.constructor);
  }
})

```
Because the message object is of type `OutgoingMessage`, this means that all the helper functions to compose said object are now available to you. See what functions are made available in the API reference: [here](/api-reference/outgoing-message.md)

Now I realise you might not actually want to wait until you are inside of an outgoing middleware controller to have access to those OutgoingMessage helper functions. This is why you can create them from your bot object directly using the `createOutgoingMessage` helper methods that come with all bot instances. Again, checkout the [api-reference for BaseBot](/api-reference/base-bot.md) to see how to use them.