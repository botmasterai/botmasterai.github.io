# Incoming update

Standardization is at the heart of Botmaster. The framework was really created for that purpose. This means that updates coming from any platform have to have the same format.

In order to do that, the **Facebook Messenger update/message format** was chosen and adopted. This means that when your botmaster object receives an 'update' from anywhere, you can be sure that it will be of the same format as a similar message that would come from Facebook Messenger.

Typically, it would look something like this for a message with an image attachment. Independent of what platform the message comes from:

```js
{
  raw: <platform_specific_raw_update>,
  sender: {
    id: <id_of_sender>
  },
  recipient: {
    id: <id_of_the_recipent> // will typically be the bot's id
  },
  timestamp: <unix_miliseconds_timestamp>,
  message: {
    mid: <message_id>,
    seq: <message_sequence_id>,
    attachments: [
      {
        type: 'image',
        payload: {
          url: 'https://scontent.xx.fbcdn.net/v/.....'
        }
      }
    ]
  }
};
```

This allows developers to handle these messages in one place only rather than doing it in multiple places. For more info on the various incoming messages formats, read the messenger bot doc on webhooks at: https://developers.facebook.com/docs/messenger-platform/webhook-reference/message-received.

Currently, you will only get updates for `Messages` (and not delivery, echo notification etc) for all platforms. On Messenger, it is assumed that you don't want to get updates for delivery, read and echo. This can't be turned on at the moment, but will be in later versions as it might be a requirement.

#### Note on attachment types and conversions
Attachment type conversion on incoming updates works as such for __Twitter__:

| Twitter Type | Botmaster conversion
|--- |---
| photo | image
| video  | video
| gif  | video

!!!Yes `gif` becomes a `video`. because Twitter doesn't actually use gifs the way you would expect it to. It simply loops over a short `.mp4` video.

Also, here's an important caveat for Twitter bot developers who are receiving attachments. Image links that come in from the Twitter API will be private and not public, which makes using them quite tricky. You might need to make authenticated requests to do so. The twitterBot objects you will receive in the update will have a `bot.twit` object. Documentation for how to use this is available [here](https://github.com/ttezel/twit).

Receiving and sending attachments [the Botmaster way] is not yet supported on **Slack** as of version 2.2.3. However, Slack supports url unfurling (meaning if you send images and other types of media urls in your message, this will be shown in the messages and users won't just see a url). Also, because of how Botmaster is built (i.e. keep all information from the original message) you can find all the necessary information in the `update.raw` object of the update.

Attachment type conversion works as such for __Telegram__:

| Telegram Type | Botmaster conversion
|--- |---
| audio | audio
| voice  | audio
| photo  | image
| video  | video
| location  | location
| venue  | location

`contact` attachment types aren't supported in Messenger. So in order to deal with them in Botmaster, you will have to look into your `update.raw` object which is the standard Telegram update. You will find your contact object in `update.raw.contact`.

Also, concerning `location` and `venue` attachments. The url received in Botmaster for Telegram is a google maps one with the coordinates as query parameters. It looks something like this: `https://maps.google.com/?q=<lat>,<long>`

A few of you will want to use attachments with your `socket.io` bots. Because the Botmaster message standard is the Facebook Messenger one, everything is URL based. Which means it is left to the developer to store both incoming and outgoing attachments. A tutorial on how to deal with this will be up soon in the [Tutorials](/tutorials) section.