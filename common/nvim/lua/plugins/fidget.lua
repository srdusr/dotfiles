require("fidget").setup({
  --event = "LspAttach",
  text = {
    --spinner = "pipe",         -- (Default) animation shown when tasks are ongoing
    --spinner = "hamburger",         -- animation shown when tasks are ongoing
    --spinner = "dots_pulse",         -- animation shown when tasks are ongoing
    spinner = "dots",        -- animation shown when tasks are ongoing
    done = "✔",            -- character shown when all tasks are complete
    commenced = "Started",   -- message shown when task starts
    completed = "Completed", -- message shown when task completes
  },
  fmt = {
    task = function(task_name, message, percentage)
      if task_name == "diagnostics" then
        return false
      end
      return string.format(
        "%s%s [%s]",
        message,
        percentage and string.format(" (%s%%)", percentage) or "",
        task_name
      )
    end,
  },
  --sources = {                 -- Sources to configure
  --["null-ls"] = {         -- Name of source
  --ignore = true,        -- Ignore notifications from this source
  --},
  --},
  debug = {
    logging = false, -- whether to enable logging, for debugging
    strict = false,  -- whether to interpret LSP strictly
  },
})
