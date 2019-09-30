/*
 * *******************************************************************************
 *   Copyright (c) 2019 Edgeworx, Inc.
 *
 *   This program and the accompanying materials are made available under the
 *   terms of the Eclipse Public License v. 2.0 which is available at
 *   http://www.eclipse.org/legal/epl-2.0
 *
 *   SPDX-License-Identifier: EPL-2.0
 * *******************************************************************************
 */

const ioFogClient = require('@iofog/nodejs-sdk')
const express = require('express')
const app = express()
const path = require('path')
const _ = require('lodash')
const fs = require('fs')

const logo = 'data:image/png;base64,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'

const PORT = process.env.PORT || 80
const messageLimit = 20
const msgsBuffer = []

const main = () => {
  // Start http server
  runServer()

  // Handle ioFog
  ioFogClient.wsControlConnection(
    {
      'onNewConfigSignal':
                      function onNewConfigSignal () {
                        // upon receiving signal about new config available -> go get it
                        // fetchConfig();
                      },
      'onError':
                      function onControlSocketError (error) {
                        console.error('There was an error with Control WebSocket connection to ioFog: ', error)
                      }
    }
  )
  ioFogClient.wsMessageConnection(
    function (ioFogClient) { /* don't need to do anything on opened Message Socket */ },
    {
      'onMessages':
                      function onMessagesSocket (messages) {
                        if (messages) {
                          // when getting new messages we store newest and delete oldest corresponding to configured limit
                          for (let i = 0; i < messages.length; i++) {
                            if (msgsBuffer.length > (messageLimit - 1)) {
                              msgsBuffer.splice(0, (msgsBuffer.length - (messageLimit - 1)))
                            }
                            const message = messages[i]
                            message.contentdata = JSON.parse(message.contentdata.toString('ascii'))
                            // Write the images locally to be served as static assests
                            const fileName = `static/img_${msgsBuffer.length}.png`
                            fs.writeFileSync(fileName, message.contentdata.image_b64, 'base64')
                            message.contentdata.image_url = `/${fileName}`
                            msgsBuffer.push(message)
                          }
                        }
                      },
      'onMessageReceipt':
                      function (messageId, timestamp) { /* we received the receipt for posted msg */ },
      'onError':
                      function onMessageSocketError (error) {
                        console.error('There was an error with Message WebSocket connection to ioFog: ', error)
                      }
    }
  )
}

const runServer = () => {
  app.set('views', path.join(__dirname, 'views'))
  app.set('view engine', 'hbs')

  app.use('/static', express.static('static'))

  app.get('/', (req, res) => {
    /*
    ** Creates a map from type to an array of objects used by handlebars to create the HTML file
    */
    const dataPerType = msgsBuffer.reduce((result, data) => {
      data.contentdata.detections.forEach(d => {
        const viewObj = {
          ...d,
          image_url: data.contentdata.image_url,
          publisher: data.contentdata.publisher,
          badgeColor: `hsl(${(d.probability * 1.2).toString(10)},100%,50%)`
        }
        if (!result[d.name]) {
          result[d.name] = [viewObj]
        } else {
          result[d.name].push(viewObj)
        }
      })
      return result
    }, {})
    const dataPerTypeSorted = _.mapValues(dataPerType, perTypeArray => perTypeArray.sort((a, b) => b.probability - a.probability))
    res.render('index', { data: dataPerTypeSorted, title: 'Edgeworx demo', logo, raw: JSON.stringify(dataPerType, null, 2) })
  })

  app.get('/raw', (req, res) => {
    res.status(200).json(msgsBuffer)
  })

  app.listen(PORT)
}

ioFogClient.init('iofog', 54321, null, main)
