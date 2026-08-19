-- kulala.nvim: a REST client that runs .http/.rest files directly in Neovim,
-- similar to the VS Code REST Client extension. Requires curl (system) and
-- uses jq to pretty-print JSON responses.
return {
	{
		"mistweaverco/kulala.nvim",
		ft = { "http", "rest" },
		opts = {
			-- Register kulala's default keymaps (buffer-local, under this prefix)
			-- whenever an http/rest buffer opens.
			global_keymaps = true,
			global_keymaps_prefix = "<leader>R",
			-- Pretty-print JSON/HTML/XML response bodies with the matching tool.
			contenttypes = {
				["application/json"] = {
					ft = "json",
					formatter = { "jq", "." },
				},
			},
		},
	},
}
