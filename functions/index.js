const functions = require('firebase-functions')
const admin = require('firebase-admin')
admin.initializeApp()

exports.sendNotification = functions.firestore
  .document('messages/{groupId1}/{groupId2}/{message}')
  .onCreate((snap, context) => {
    console.log('----------------start function--------------------')

    const doc = snap.data()
    console.log(doc)

    const idFrom = doc.idFrom
    const idTo = doc.idTo
    const contentMessage = doc.content
    console.log(`Send from : ${idFrom}`)

    // Get push token user to (receive)
    admin
      .firestore()
      .collection('user')
      .where('id', '==', idTo)
      .get()
      .then(querySnapshot => {
        querySnapshot.forEach(userTo => {
        //Change nickname to name
          console.log(`Found user to: ${userTo.data().name}`)
          console.log(`Found user chatWith : ${userTo.data().chatWith[0]}`)
          console.log(`Send from : ${idFrom}`)
          if (userTo.data().token && userTo.data().chatWith[0] == idFrom) {
            // Get info user from (sent)
            admin
              .firestore()
              .collection('user')
              .where('id', '==', idFrom)
              .get()
              .then(querySnapshot2 => {
                querySnapshot2.forEach(userFrom => {
                //Change nickname to name
                  console.log(`Found user from: ${userFrom.data().name}`)
                  const payload = {
                    notification: {
                    //Change nickname to name
                      title: `${userFrom.data().name} sent a message`,
                      body: contentMessage,
                      badge: '1',
                      sound: 'default',

                    }
                  }
                  // Let push to the target device
                  admin
                    .messaging()
                    .sendToDevice(userTo.data().token, payload)
                    .then(response => {
                      console.log('Successfully sent message:', response)
                    })
                    .catch(error => {
                      console.log('Error sending message:', error)
                    })
                })
              })
          } else {
            console.log('Can not find pushToken target user')
          }
        })
      })
    return null
  })