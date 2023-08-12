# OpenAI API Wrapper for the gamesense lua api

A simple and efficient Lua wrapper for OpenAI's GPT models, built with ease-of-use and extensibility in mind.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Contribute](#contribute)
- [License](#license)

## Features

- Utilizes the OpenAI GPT models including `gpt-3.5-turbo` and `gpt-4`.
- Supports both single and streaming requests.
- Built-in utility functions for text manipulation.
- Extendable for further enhancements.

## Installation

1. Clone the repository:

```bash
git clone https://github.com/mariolua/openai-api-wrapper-for-gamesense.git
```

## Usage

```lua
-- Import the OpenAI API module
local Chatbot = require("openai_api")

-- Configuration table for the chatbot
local t = {
    api_key = 'YOUR API KEY',
    engine = 'gpt-3.5-turbo-16k',
    timeout = 60,
    max_tokens = nil,
    temperature = 1.2,
    top_p = 0.9,
    presence_penalty = 0.0,
    frequency_penalty = 0.0,
    reply_count = 1,
    truncate_limit = nil,
    system_prompt = [[You are Vexanor Voidstalker, aka Vex.
                      You are an evil individual.]],
    convo_id = 'default'
}

-- Initialize the chatbot with the provided configuration
local chatbot = Chatbot.new(t.api_key, t.engine, t.timeout, t.max_tokens, t.temperature, t.top_p, t.presence_penalty, t.frequency_penalty, t.reply_count, t.truncate_limit, t.system_prompt, t.convo_id)

-- Variable to store the previous response
local prev_response

-- Function to periodically print the chatbot's response
local function loop()
    if chatbot.full_response ~= prev_response then
        print(chatbot.full_response)
        prev_response = chatbot.full_response
    end
    client.delay_call(0.5, loop)
end

-- Start the loop
loop()

 -- handle console input
local cb_mode
-- Function to handle the console input commands
local function con_cmds(input)
    input = input:lower()

    -- Check if input starts with 'cb'
    if input:sub(1, 2) == "cb" then
        local cmd = input:sub(4)

        -- Define command actions
        local commands = {
            hdf = function()
                cb_mode = false
                print("*Chatbot terminated*")
            end,
            stop = function()
                cb_mode = false
                print("*Chatbot terminated*")
            end,
            unload = function()
                cb_mode = false
                print("*Chatbot unloaded*")
                client.unset_event_callback('console_input', con_cmds)
            end,
        }

        -- Execute matching command
        if commands[cmd] then
            commands[cmd]()
            return true
        else
            cb_mode = true  -- Switch to chatbot mode if no matching command
        end
    end

    -- If in chatbot mode and input is not a command, process as a message
    if cb_mode then
        chatbot:ask(string.format('Mario: %s', input))
        return true
    end
end

-- Setting up an event callback to trigger the `con_cmds` function whenever a console_input event is detected
client.set_event_callback('console_input', con_cmds)

```

## Contribute

We welcome contributions to the OpenAI API Wrapper for Lua! If you'd like to contribute, please:

1. Fork the repository.
2. Create a new branch.
3. Make your changes and push them to your branch.
4. Open a Pull Request.

For major changes, please open an issue first to discuss the change.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
