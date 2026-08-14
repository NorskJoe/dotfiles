return {
  {
    "danymat/neogen",
    event = "VeryLazy",
    opts = { snippet_engine = "nvim" },
    keys = {
      { "<leader>cd", function() require("neogen").generate() end, desc = "Doc Comment" },
    },
  },
}