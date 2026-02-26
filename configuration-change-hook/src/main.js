#!/usr/local/bin/node

const fs = require("fs")
const { connectAsync } = require("@artcom/mqtt-topping")
const git = require("./git")

const CHANGE_EVENT_TOPIC = `${process.env.BASE_TOPIC}/onConfigurationChange`

async function main() {
  const mqttClient = await connectAsync(process.env.TCP_BROKER_URI, {
    appId: "configuration-change-hook",
  })
  const changedRefs = fs.readFileSync(0).toString().split("\n").slice(0, -1)

  for (const ref of changedRefs) {
    const [oldValue, newValue, refName] = ref.split(" ")
    console.log(`${refName} changed`)
    const changedFiles = git("diff", "--name-only", oldValue, newValue).split("\n")
    await mqttClient.publish(CHANGE_EVENT_TOPIC, { refName, changedFiles })
  }
  console.log(`Published ${CHANGE_EVENT_TOPIC}`)
  await mqttClient.disconnect()
}

main()
