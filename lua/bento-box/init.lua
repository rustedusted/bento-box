local M = {}
-- TODO: create a setup function that would use a flag that would smartly check if the setup is executed only once
-- setup will do the following things
-- return if flag true
-- set flag as the setup function is executing for the first time
-- set the autocommand and variables that are required like the M.buf,M.win and split_win(flag will remain outside)  TODO:read other codes by devs to see the tricks they used to implement setup being executed only once
-- execute the autocommand
-- end
function M.open_floating_win(filename)
	if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
		if not M.buf or not M.win then
			error("inconsistent M.buf and M.win")
		end

		local fname = vim.api.nvim_buf_get_name(0)
		vim.api.nvim_buf_delete(M.buf, {})
		if vim.api.nvim_win_is_valid(M.win) then
			vim.api.nvim_win_close(M.win, true)
			M.win, M.buf = nil, nil
		end
		if fname == filename then
			return
		end
	end
	-- Get the current editor size
	local editor_width = vim.o.columns

	local editor_height = vim.o.lines - 4

	-- Set the dimensions of the floating window
	local win_width = math.floor(editor_width * 0.5) -- 50% of the editor width
	local win_height = math.floor(editor_height * 0.7) -- 70% of the editor height
	local win_row = math.floor((editor_height - win_height) / 2) -- Center vertically
	local win_col = math.floor((editor_width - win_width) / 2) -- Center horizontally

	-- Define the window options
	local opts = {
		relative = "editor",
		width = win_width,
		height = win_height,
		row = win_row,
		col = win_col,
		style = "minimal",
		border = "rounded",
	}

	M.buf = vim.api.nvim_create_buf(false, false)
	M.win = vim.api.nvim_open_win(M.buf, true, opts)
	vim.api.nvim_command("e " .. filename)
	vim.api.nvim_buf_set_keymap(M.buf, "n", "<Esc>", "<Esc>:wq<CR>", {})
	vim.api.nvim_buf_set_keymap(M.buf, "i", "<Esc>", "<Esc>:wq<CR>", {})

	return M.buf, M.win
end

M.setup = function()
	if M.flag then
		return
	end
	M.flag = true
	M.buf, M.win = nil, nil
	M.split_win = nil
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "fsr.cpp",
		callback = function()
			local filename = vim.fn.expand("%") -- Get the current buffer's filename
			local cmd = string.format(
				"g++ -g -fsanitize=address -std=c++17 -Wall -Wextra -Wshadow -DONPC -O2 -o a.out %s && ./a.out < /tmp/inp > /tmp/dyn-out 2>&1; rm a.out",
				filename
			)
			vim.fn.jobstart(cmd, {
				on_exit = function(_, code)
					M.code()
					M.code()
					print("Compilation and execution finished with exit code: " .. code)
				end,
			})
		end,
	})
end

M.code = function()
	if split_win and vim.api.nvim_win_is_valid(split_win) then
		vim.api.nvim_win_close(split_win, true)
		split_win = nil
	elseif vim.fn.expand("%"):match("fsr%.cpp$") then
		local curr = vim.api.nvim_get_current_win()
		vim.api.nvim_command("vsplit /tmp/dyn-out")
		split_win = vim.api.nvim_get_current_win()
		vim.api.nvim_set_current_win(curr)
	else
		print("not opened fsr.cpp")
		split_win = nil
		return
	end
end
M.input = function()
	M.open_floating_win("/tmp/inp")
end
M.output = function()
	M.open_floating_win("/tmp/out")
end

-- Create a command to trigger the greet function
vim.api.nvim_create_user_command("FSRinp", M.input, {})
vim.api.nvim_create_user_command("FSRout", M.output, {})
vim.api.nvim_create_user_command("FSRcode", M.code, {})
vim.keymap.set("n", "<leader>ci", M.input)
vim.keymap.set("n", "<leader>co", M.output)
vim.keymap.set("n", "<leader>cp", M.code)

return M
