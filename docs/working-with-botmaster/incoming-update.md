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

To know which kind of updates you'll get from the various platforms, have a look at the `bot.receives` values. See [here](/working-with-botmaster/bot-object.html#1-botreceives). This will help you discriminate between which bot you receive what kind of updates from. And thus in turn where you want to send which messages.
