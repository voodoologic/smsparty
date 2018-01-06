# smsparty
Originally made for DefCon when all my coworkers had burner phones.
smsparty sms proxy for distributed text messaging.  It lets you add new users via text.  Good for growing group texts, away team travels where people's numbers are changing, or my recent bachelor party.

## edit a secrets.yml file
(emails not necessary or utilized at this point)
```
---
account_sid: "TwilloAccountSIDNumber"
auth_token: "TwillioSecretTocket"
phone_number: '+12065557575' #twillio number
users:
  - name: Doug🌹
    phone: '+14155557979'
    email: example@gmail.com
  - name: James
    phone: '+15095557878'
    email: example@yahoo.com
  - name: Gabe🏅,
    phone: '+12545557676'
    email: example@hotmail.com
```
### help menu
```
~help display this message
~stop stop messages from flowing
~start start messages flowing
~name change your name
~list list users
```
## install dependencies
`bundle`

## start the server
`rackup`

