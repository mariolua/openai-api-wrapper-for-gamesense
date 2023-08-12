-- It's a me, Mario

-- Import required libraries
local json = require("json")
local http = require "gamesense/http"

-- Helper function to find a value in a table
-- @param tbl: table to search
-- @param value: value to find
-- @return: index of the value or nil if not found
local function table_find(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

-- Helper function to split a string by "data: " prefix
-- @param str: string to split
-- @return: table of split values
local function splitByDataPrefix(str)
    local results = {}
    for segment in string.gmatch(str, "data: ([^\\n]+)") do
        table.insert(results, segment)
    end
    return results
end

-- Helper function to count words in a string
-- @param str: string to count words in
-- @return: number of words in the string
local function countWords(str)
    local count = 0
    for word in str:gmatch("%S+") do
        count = count + 1
    end
    return count
end

-- List of available engines
local ENGINES = {
    "gpt-3.5-turbo",
    "gpt-3.5-turbo-16k",
    "gpt-3.5-turbo-0301",
    "gpt-3.5-turbo-0613",
    "gpt-3.5-turbo-16k-0613",
    "gpt-4",
    "gpt-4-0314",
    "gpt-4-32k",
    "gpt-4-32k-0314",
    "gpt-4-0613",
    "gpt-4-32k-0613"
}

-- Chatbot class
local Chatbot = {}
Chatbot.__index = Chatbot

-- Constructor for Chatbot class
-- @params: various configuration parameters for the chatbot
-- @return: an instance of the Chatbot
function Chatbot.new(api_key, engine, timeout, max_tokens, temperature, top_p, presence_penalty, frequency_penalty, reply_count, truncate_limit, system_prompt, convo_id)
    local self = setmetatable({}, Chatbot)
    self.engine = engine or "gpt-3.5-turbo"
    self.model = self.engine
    self.api_key = api_key
    self.system_prompt = system_prompt or "You are a dumb chatbot"
    self.max_tokens = max_tokens or (string.find(engine, "gpt-4-32k") and 31000 or (string.find(engine, "gpt-4") and 7000 or (string.find(engine, "gpt-3.5-turbo-16k") and 15000 or 4000)))
    self.truncate_limit = truncate_limit or (string.find(engine, "gpt-4-32k") and 30500 or (string.find(engine, "gpt-4") and 6500 or (string.find(engine, "gpt-3.5-turbo-16k") and 14500 or 3500)))
    self.temperature = temperature or 0.5
    self.top_p = top_p or 1.0
    self.presence_penalty = presence_penalty or 0.0
    self.frequency_penalty = frequency_penalty or 0.0
    self.reply_count = reply_count or 1
    self.timeout = timeout or 600
    self.convo_id = convo_id or "default"
    self.response = ''
    self.full_response = ''

    -- Additional initialization code here...
    return self
end

-- Function to ask a question to the chatbot in streaming mode
-- @params: various parameters related to the question and configuration
-- @return: chatbot's response if await async shit would be possible in that lua api
function Chatbot:ask_stream(prompt, role, convo_id, model, pass_history, ...)
    local url = "https://api.openai.com/v1/engines/" .. self.engine .. "/completions"
    local headers = { Authorization = "Bearer " .. self.api_key, "Content-Type" = "application/json" }
    local parameters = {
        prompt = prompt,
        temperature = self.temperature,
        max_tokens = self.max_tokens,
        top_p = self.top_p,
        frequency_penalty = self.frequency_penalty,
        presence_penalty = self.presence_penalty,
        n = self.reply_count,
        user = role,
        max_tokens = self:get_max_tokens(self.convo_id)
    }

    self.response = ''
    self.stream_done = false

    return http.post(url, {stream_response = parameters.stream, network_timeout = 15, absolute_timeout = 15, headers = headers, body = json.stringify(parameters)}, {
        headers_received = function(success, data)
            -- Callback for when headers are received
        end,
        data_received = function(success, data)
            -- Callback for when data is received
            local split = splitByDataPrefix(data.body)
            for i=1, #split do
                if split[i] ~= '[DONE]' then
                    local resp = json.parse(split[i])
                    local token = resp.choices[1].delta.content or ''
                    self.response = self.response .. token
                else
                    self.stream_done = true
                end
            end
        end,
        complete = function(success, response)
            -- Callback for when the request is completed
            if not success or response.status ~= 200 then
                error((response.status or '') .. " " .. (response.status_message or '') .. " " .. (response.body or ''))
            end
            self.full_response = self.response
            self:add_to_conversation(self.response, 'assistant', self.convo_id)
            self:save_conversation()
			return self.response
        end
    })
end

-- Function to ask a question to the chatbot
-- @params: various parameters related to the question and configuration
-- @return: chatbot's response if await async shit would be possible in that lua api
function Chatbot:ask(prompt, role, convo_id, model, pass_history, ...)
    role = role or 'user'
    convo_id = convo_id or self.convo_id
    model = model or self.model
    pass_history = pass_history or true

    return self:ask_stream(prompt, role, self.convo_id, model, pass_history, ...)
end

-- Function to rollback the chatbot's conversation
-- @params: number of messages to rollback and conversation id
function Chatbot:rollback(n, convo_id)
    for _ = 1, n do
        table.remove(self.conversation[self.convo_id])
    end
    self:save_conversation()
end

-- Function to reset the chatbot's conversation
-- @params: conversation id and system prompt
function Chatbot:reset(convo_id, system_prompt)
    self.conversation[self.convo_id] = {
        {
            role = "system",
            content = system_prompt or self.system_prompt
        }
    }
    self:save_conversation()
end

return Chatbot
