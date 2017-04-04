### Outgoing messages

Again, outgoing messages are expected to be formatted like messages the Messenger platform would expect. They will typically look something like this for a text message:

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
botmaster.on('update', (bot, update) => {
  const message = {
    recipient: {
      id: update.sender.id,
    },
    message: {
      text: 'Some arbitrary text of yours'
    },
  };
  bot.sendMessage(message);
});
```

typically, you would want to perform some action upon confirmation that the message was sent or catch a potential error. doing so is done like this:

```js
botmaster.on('update', (bot, update) => {
  .
  .
  bot.sendMessage(message)

  .then((body) => {
    console.log(body);
  })

  .catch((err) => {
    console.log(err.message);
  })
});

```

The `body` part of the response has the following structure:


| Argument | Description
|--- |---
| raw | raw response body (response from the platform).
| recipient_id | id of user who sent the message
| message_id | id of message that was just sent
| sent_message | full object that was just sent after going through all the outgoing middlewares

You can also opt to use callbacks rather than promises and this would work as such:

```js
botmaster.on('update', (bot, update) => {
  .
  .
  bot.sendMessage(message, (err, body) => {
    if (err) {
      return console.log(err.message);
    }

    console.log(body);
  });
});
```

Typically, this method (and all its accompanying helper ones that follow) will hit all your setup outgoing middleware (read more about middleware [here](/working-with-botmaster/middleware) if you don't know about them yet). If you want to avoid that and ignore your setup middleware in certain situations, do something like this:

```js
botmaster.on('update', (bot, update) => {
  .
  .
  bot.sendMessage(message, { ignoreMiddleware: true })
});
```

And its signature is as follows:

`bot.sendMessage`

| Argument | Description
|--- |---
| message | a full valid messenger message object.
| sendOptions | (__optional__) an object containing options regarding the sending of the message. One of those options is: `ignoreMiddleware`.
| cb | (__optional__) callback function if you don't want to use botmaster with promises.

As you can see, the `sendMessage` method used is used directly from the bot object and not using the botmaster one.

Because you might not always want to code in a complex json object just to send in a simple text message or photo attachment, Botmaster comes with a few helper methods that can be used to send messages with less code:

`bot.sendMessageTo`

| Argument | Description
|--- |---
| message | an object without the recipient part. In the previous example, it would be `message.message`.
| recipientId  | a string representing the id of the user to whom you want to send the message.
| sendOptions | (__optional__) an object containing options regarding the sending of the message. One of those options is: `ignoreMiddleware`.
| cb | (__optional__) callback function if you don't want to use botmaster with promises.

`bot.sendTextMessageTo`

| Argument | Description
|--- |---
| text | just a string with the text you want to send to your user
| recipientId  | a string representing the id of the user to whom you want to send the message.
| sendOptions | (__optional__) an object containing options regarding the sending of the message. One of those options is: `ignoreMiddleware`.
| cb | (__optional__) callback function if you don't want to use botmaster with promises.

Typically used like so to send a text message to the user who just spoke to the bot:

```js
botmaster.on('update', (bot, update) => {
  bot.sendTextMessageTo('something super important', update.sender.id);
});
```

`bot.reply`

| Argument | Description
|--- |---
| update | an update object with a valid `update.sender.id`.
| text  | just a string with the text you want to send to your user
| sendOptions | (__optional__) an object containing options regarding the sending of the message. One of those options is: `ignoreMiddleware`.
| cb | (__optional__) callback function if you don't want to use botmaster with promises.

This is is typically used like so:

```js
botmaster.on('update', (bot, update) => {
  bot.reply(update, 'something super important!');
});
```

#### Attachments

`bot.sendAttachmentTo`

We'll note here really quickly that Messenger only takes in urls for file attachment (image, video, audio, file). Most other platforms don't support sending attachments in this way. So we fall back to sending the url in text which really results in a very similar output. Same goes for Twitter that doesn't support attachments at all.

| Argument | Description
|--- |---
| attachment | a valid Messenger style attachment. See [here](https://developers.facebook.com/docs/messenger-platform/send-api-reference) for more on that.
| recipientId  | a string representing the id of the user to whom you want to send the message.
| sendOptions | (__optional__) an object containing options regarding the sending of the message. One of those options is: `ignoreMiddleware`.
| cb | (__optional__) callback function if you don't want to use botmaster with promises.

This is the general attachment sending method that will always work for Messenger but not necessarily for other platforms as Facebook Messenger supports all sorts of attachments that other platforms don't necessarily support. So beware when using it. To assure your attachment will be sent to all platforms, use `bot.sendAttachmentFromURLTo`.

This is typically used as such for sending an image url.

```js
botmaster.on('update', (bot, update) => {
  const attachment = {
    type: 'image'
    payload: {
      url: "some image url you've got",
    },
  };
  bot.sendAttachment(attachment, update.sender.id);
});
```

`bot.sendAttachmentFromURLTo`

Just easier to use this to send standard url attachments. And URL attachments if used properly should work on all out-of-the-box platforms:

| Argument | Description
|--- |---
| type | string representing the type of attachment (audio, video, image or file)
| url  | the url to your file
| recipientId  | a string representing the id of the user to whom you want to send the message.
| sendOptions | (__optional__) an object containing options regarding the sending of the message. One of those options is: `ignoreMiddleware`.
| cb | (__optional__) callback function if you don't want to use botmaster with promises.

This is typically used as such for sending an image url.

```js
botmaster.on('update', (bot, update) => {
  bot.sendAttachmentFromURLTo('image', "some image url you've got", update.sender.id);
});
```

#### Status

`bot.sendIsTypingMessageTo`

To indicate that something is happening on your bots end, you can show your users that the bot is 'working' or 'typing' something. to do so, simply invoke sendIsTypingMessageTo.

| Argument | Description
|--- |---
| recipientId  | a string representing the id of the user to whom you want to send the message.
| sendOptions | (__optional__) an object containing options regarding the sending of the message. One of those options is: `ignoreMiddleware`.
| cb | (__optional__) callback function if you don't want to use botmaster with promises.

It is used as such:

```js
botmaster.on('update', (bot, update) => {
  bot.sendIsTypingMessageTo(update.sender.id);
});
```

It will only send a request to the platforms that support it. If unsupported, nothing will happen.


#### Buttons

Buttons will almost surely be part of your bot. Botmaster provides a method that will send what is assumed to be a decent way to display buttons throughout all platforms.

`bot.sendDefaultButtonMessageTo`

| Argument | Description
|--- |---
| buttonTitles | array of button titles (no longer than 10 in size).
| recipientId  | a string representing the id of the user to whom you want to send the message.
| textOrAttachment  | (__optional__) a string or an attachment object similar to the ones required in `bot.sendAttachmentTo`. This is meant to provide context to the buttons. I.e. why are there buttons here. A piece of text or an attachment could detail that. If not provided,  text will be added that reads: 'Please select one of:'. This is only optional if none of sendOptions and cb is specified
| sendOptions | (__optional__) an object containing options regarding the sending of the message. One of those options is: `ignoreMiddleware`.
| cb | (__optional__) callback function if you don't want to use botmaster with promises.

The function defaults to sending `quick_replies` in Messenger, setting `Keyboard buttons` in Telegram, buttons in Slack and simply prints button titles one on each line in Twitter as it doesn't support buttons. The user is expecting to type in their choice in Twitter. In the socketio implementation, the front-end/app developer is expected to write the code that would display the buttons on their front-end.

It is used as such:

```js
botmaster.on('update', (bot, update) => {
  const buttonArray = ['button1', 'button2'];
  bot.sendDefaultButtonMessageTo(buttonArray, update.sender.id,
    'Please select "button1" or "button2"');
});
```

>If you will be using either of `sendOptions` or `cb`, you will need to specify `textOrAttachment`.


#### Cascade

In order to send a cascade of messages (i.e. multiple messages one after another), you might want to have a look at both of these methods:

`bot.sendCascadeTo`

| Argument | Description
|--- |---
| messageArray | Array of messages in a format as such: [{text: 'something'}, {message: someMessengerValidMessage}] read below to see valid keys.
| recipientId  | a string representing the id of the user to whom you want to send the message.

As you might have guessed, Botmaster assures you that the objects in the messageArray will be sent in order. Furthermore, the objects of the messageArray must be of a certain form where valid params are the following:

```js
{
  raw: SOME_VALID_RAW_MESSAGE, // the same object as one you would send with sendRaw()
  message: SOME_VALID_MESSENGER_MESSAGE, // the same object as one you would send with sendMessage() (i.e. the recipientId won't be taken into account!)
  buttons: SOME_ARRAY_OF_BUTTON_TITLES, // same as what you would do with: sendDefaultButtonMessageTo. If you will be sending attachments/text alongside it, add them in the following fields. If both are present, the attachment will be used.
  attachment: SOME_ATTACHMENT, // same object format as in: sendAttachmentTo()
  text: 'some text', // same as when using sendTextMessageTo()
  isTyping: SOME_TRUTHY_VALUE, // will call sendIsTypingMessageTo() on the recipientId used in sendCascade.
}
```

>It is important to note that all these parameters will be hit in the shown order if present. I.e. if `raw` is present, `message` will not be hit nor will `buttons` be hit etc.

You could typically use this as such:

```js
botmaster.on('update', (bot, update) => {
  const rawMessage = SOME_RAW_PLATFORM_MESSAGE;

  const fullMessage = {
    recipient: {
      id: someUserId, // note that I am not using update.sender.id on purpose here, so as to show that this overrides the recipientId from the sendCascade Method
    },
    message: {
      text: 'Some arbitrary text of yours'
    },
  };

  const buttonsArray = ['button1', 'button2'];
  const textForButtons = 'Please select one of the two buttons';

  const someText = 'some text message after all this';

  bot.sendCascadeTo([
    { raw: rawMessage},
    { message: fullMessage },
    { isTyping: true },
    { buttons: buttonsArray,
      text: textForButtons
    },
    { isTyping: true },
    { text: someText },
  ], update.sender.id)
});

```
Where our `recipientId` is set to `update.sender.id`.

In this example, the bot will send a rawMessage and then a botmaster supported message to the platform (both these messages will not take into consideration the recipientId (update.sender.id) set in sendCascade). Then it will send a button message and then a standard text message. Both these last messages will be sent to the specified recipientId (again, update.sender.id). Note that before each message sent to the recipient, I also send an 'isTyping' message to the recipient. I purposefully do not do so for the first two messages as it is assumed here that those messages are not being sent to the recipient, but to some other user.

`bot.sendTextCascadeTo`

| Argument | Description
|--- |---
| textMessageArray | Array of strings that you want to send to the user in sequences.
| recipientId  | a string representing the id of the user to whom you want to send the message.

This method is really just a helper for calling `bot.sendCascadeTo`. It just allows developers to use the method with an array of texts rather than an array of objects.

Something like this will do:

```js
bot.sendTextCascadeTo(['message1', 'message2'], user.sender.id);
```

`sendOptions` is an optional argument that can take in the following parameters (for now)

| key/option |  Description
|--- |---
| ignoreMiddleware | outgoing middleware will not be hit if this parameter is set to true (or any truthy value)

If you want to learn more about middleware and why you might want to use any of these options, read more about middleware [here](/working-with-botmaster/middleware)
