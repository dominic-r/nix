{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Install plugins
    plugins = with pkgs.vimPlugins; [
      # Treesitter for syntax highlighting
      (nvim-treesitter.withPlugins (p: [
        p.typescript
        p.tsx
        p.javascript
        p.go
        p.python
        p.markdown
        p.markdown_inline
        p.nix
        p.lua
        p.json
        p.yaml
        p.css
        p.scss
      ]))

      # File navigation and fuzzy finding
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      nvim-tree-lua
      nvim-web-devicons

      # Git integration
      gitsigns-nvim

      # UI improvements
      lualine-nvim
      bufferline-nvim
      indent-blankline-nvim

      # Color scheme
      tokyonight-nvim

      # Utilities
      nvim-autopairs
      vim-surround
      which-key-nvim
      toggleterm-nvim
    ];

    extraPackages = with pkgs; [
      # Search and navigation tools
      ripgrep
      fd
      fzf
      tree-sitter
    ];

    initLua = ''
      -- ============================================================================
      -- General Settings
      -- ============================================================================

      vim.g.mapleader = ' '
      vim.g.maplocalleader = ' '

      local opt = vim.opt

      -- Line numbers
      opt.number = true
      opt.relativenumber = true

      -- Tabs and indentation
      opt.tabstop = 2
      opt.shiftwidth = 2
      opt.expandtab = true
      opt.autoindent = true
      opt.smartindent = true

      -- Search
      opt.ignorecase = true
      opt.smartcase = true
      opt.hlsearch = true
      opt.incsearch = true

      -- UI
      opt.termguicolors = true
      opt.background = 'dark'
      opt.signcolumn = 'yes'
      opt.cursorline = true
      opt.wrap = false
      opt.scrolloff = 8
      opt.sidescrolloff = 8

      -- Behavior
      opt.mouse = 'a'
      opt.clipboard = 'unnamedplus'
      opt.completeopt = { 'menu', 'menuone', 'noselect' }
      opt.updatetime = 250
      opt.timeoutlen = 300

      -- Files
      opt.swapfile = false
      opt.backup = false
      opt.undofile = true
      opt.undodir = os.getenv('HOME') .. '/.vim/undodir'

      -- Split windows
      opt.splitright = true
      opt.splitbelow = true

      -- ============================================================================
      -- Color Scheme
      -- ============================================================================

      vim.cmd('colorscheme tokyonight-night')

      -- ============================================================================
      -- Key Mappings
      -- ============================================================================

      local keymap = vim.keymap.set

      -- Quick save and quit
      keymap('n', '<leader>w', ':w<CR>', { desc = 'Save file' })
      keymap('n', '<leader>q', ':q<CR>', { desc = 'Quit' })
      keymap('n', '<leader>x', ':wq<CR>', { desc = 'Save and quit' })

      -- Clear search highlighting
      keymap('n', '<leader>h', ':nohlsearch<CR>', { desc = 'Clear highlight' })

      -- Better window navigation
      keymap('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
      keymap('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
      keymap('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
      keymap('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

      -- Resize windows
      keymap('n', '<C-Up>', ':resize +2<CR>', { desc = 'Increase height' })
      keymap('n', '<C-Down>', ':resize -2<CR>', { desc = 'Decrease height' })
      keymap('n', '<C-Left>', ':vertical resize -2<CR>', { desc = 'Decrease width' })
      keymap('n', '<C-Right>', ':vertical resize +2<CR>', { desc = 'Increase width' })

      -- Buffer navigation
      keymap('n', '<Tab>', ':bnext<CR>', { desc = 'Next buffer' })
      keymap('n', '<S-Tab>', ':bprevious<CR>', { desc = 'Previous buffer' })
      keymap('n', '<leader>bd', ':bdelete<CR>', { desc = 'Delete buffer' })

      -- Move lines
      keymap('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down' })
      keymap('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up' })

      -- Keep visual mode when indenting
      keymap('v', '<', '<gv', { desc = 'Indent left' })
      keymap('v', '>', '>gv', { desc = 'Indent right' })

      -- ============================================================================
      -- Treesitter
      -- ============================================================================

      -- Configure folding with treesitter
      vim.opt.foldmethod = 'expr'
      vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.opt.foldenable = false  -- Start with folds open

      -- Incremental selection keymaps using treesitter
      keymap('n', '<CR>', function()
        require('nvim-treesitter.incremental_selection').init_selection()
      end, { desc = 'Init treesitter selection' })
      keymap('x', '<CR>', function()
        require('nvim-treesitter.incremental_selection').node_incremental()
      end, { desc = 'Increment treesitter selection' })
      keymap('x', '<S-CR>', function()
        require('nvim-treesitter.incremental_selection').node_decremental()
      end, { desc = 'Decrement treesitter selection' })

      -- ============================================================================
      -- Telescope
      -- ============================================================================

      local telescope = require('telescope')
      local actions = require('telescope.actions')

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ['<C-j>'] = actions.move_selection_next,
              ['<C-k>'] = actions.move_selection_previous,
              ['<C-q>'] = actions.close,
            },
          },
          file_ignore_patterns = { 'node_modules', '.git/', 'target/', 'build/' },
        },
      })

      telescope.load_extension('fzf')

      -- Telescope keymaps
      keymap('n', '<leader>ff', ':Telescope find_files<CR>', { desc = 'Find files' })
      keymap('n', '<leader>fg', ':Telescope live_grep<CR>', { desc = 'Live grep' })
      keymap('n', '<leader>fb', ':Telescope buffers<CR>', { desc = 'Find buffers' })
      keymap('n', '<leader>fh', ':Telescope help_tags<CR>', { desc = 'Help tags' })
      keymap('n', '<leader>fr', ':Telescope oldfiles<CR>', { desc = 'Recent files' })
      keymap('n', '<leader>fs', ':Telescope lsp_document_symbols<CR>', { desc = 'Document symbols' })

      -- ============================================================================
      -- File Explorer (nvim-tree)
      -- ============================================================================

      require('nvim-tree').setup({
        view = {
          width = 35,
        },
        renderer = {
          group_empty = true,
          icons = {
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
            },
          },
        },
        filters = {
          dotfiles = false,
        },
      })

      keymap('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle file explorer' })
      keymap('n', '<leader>ef', ':NvimTreeFindFile<CR>', { desc = 'Find file in explorer' })

      -- ============================================================================
      -- Git Signs
      -- ============================================================================

      require('gitsigns').setup({
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          keymap('n', ']h', gs.next_hunk, { buffer = bufnr, desc = 'Next hunk' })
          keymap('n', '[h', gs.prev_hunk, { buffer = bufnr, desc = 'Previous hunk' })
          keymap('n', '<leader>gs', gs.stage_hunk, { buffer = bufnr, desc = 'Stage hunk' })
          keymap('n', '<leader>gr', gs.reset_hunk, { buffer = bufnr, desc = 'Reset hunk' })
          keymap('n', '<leader>gp', gs.preview_hunk, { buffer = bufnr, desc = 'Preview hunk' })
          keymap('n', '<leader>gb', gs.blame_line, { buffer = bufnr, desc = 'Blame line' })
        end,
      })

      -- ============================================================================
      -- Statusline (lualine)
      -- ============================================================================

      require('lualine').setup({
        options = {
          theme = 'tokyonight',
          component_separators = '|',
          section_separators = "",
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
      })

      -- ============================================================================
      -- Bufferline
      -- ============================================================================

      require('bufferline').setup({
        options = {
          mode = 'buffers',
          numbers = 'none',
          diagnostics = 'nvim_lsp',
          separator_style = 'thin',
          show_buffer_close_icons = true,
          show_close_icon = true,
          offsets = {
            {
              filetype = 'NvimTree',
              text = 'File Explorer',
              text_align = 'center',
            },
          },
        },
      })

      -- ============================================================================
      -- Indent Blankline
      -- ============================================================================

      require('ibl').setup({
        indent = {
          char = '│',
        },
        scope = {
          enabled = true,
          show_start = true,
          show_end = false,
        },
      })

      -- ============================================================================
      -- Autopairs
      -- ============================================================================

      require('nvim-autopairs').setup({
        check_ts = true,
        ts_config = {
          lua = { 'string' },
          javascript = { 'template_string' },
        },
      })

      -- ============================================================================
      -- Which Key
      -- ============================================================================

      require('which-key').setup({
        plugins = {
          spelling = { enabled = true },
        },
      })

      -- ============================================================================
      -- Toggle Terminal
      -- ============================================================================

      require('toggleterm').setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_terminals = true,
        direction = 'horizontal',
        close_on_exit = true,
        shell = vim.o.shell,
      })

      -- ============================================================================
      -- Auto Commands
      -- ============================================================================

      -- Remove trailing whitespace on save
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*',
        command = [[%s/\s\+$//e]],
      })

      -- Return to last edit position
      vim.api.nvim_create_autocmd('BufReadPost', {
        pattern = '*',
        callback = function()
          local line = vim.fn.line
          if line('\'"') > 0 and line('\'"') <= line('$') then
            vim.cmd('normal! g`"')
          end
        end,
      })

      -- File type specific settings
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'python' },
        callback = function()
          vim.opt_local.tabstop = 4
          vim.opt_local.shiftwidth = 4
        end,
      })

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'go' },
        callback = function()
          vim.opt_local.tabstop = 4
          vim.opt_local.shiftwidth = 4
          vim.opt_local.expandtab = false
        end,
      })

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'markdown', 'mdx' },
        callback = function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
        end,
      })
    '';
  };
}
