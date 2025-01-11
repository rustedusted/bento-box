local M = {}

-- Define a simple command
M.greet = function()
	print("Hello from myplugin!")
end

-- Create a command to trigger the greet function
vim.api.nvim_create_user_command("GreetPlugin", M.greet, {})

return M
