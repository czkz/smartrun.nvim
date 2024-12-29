local M = {}

M.state = {
  last_picked_targets = {},
}

M.setup = function()
end

local escape = vim.fn.shellescape

local function has(arr, vals)
  for _, v in pairs(arr) do
    for _, val in pairs(vals) do
      if v == val then
        return true
      end
    end
  end
  return false
end

local function get_meson_build_dir(root_dir)
  return root_dir .. '/build'
end

local function pick_meson_target(root_dir, build_dir, this_file)
  local data = vim.fn.system('meson introspect ' .. escape(build_dir) .. ' --targets')
  local targets = vim.json.decode(data)
  -- Pick executable compiled from current file
  for _, target in pairs(targets) do
    if target.type == 'executable' then
      for _, target_source in pairs(target.target_sources) do
        if (target_source.sources) then
          for _, source in pairs(target_source.sources) do
            if source == this_file then
              local ret = { path = target.filename[1], name = target.name }
              M.state.last_picked_targets[root_dir] = ret
              return ret
            end
          end
        end
      end
    end
  end
  -- Pick same as last time
  if M.state.last_picked_targets[root_dir] then
    return M.state.last_picked_targets[root_dir]
  end
  -- Pick first executable
  for _, target in pairs(targets) do
    if target.type == 'executable' then
      return { path = target.filename[1], name = target.name }
    end
  end
end

local function wrap_cmd(cmd)
  return 'history -c; clear; ' .. cmd .. '; echo; echo Program returned $?.; read -n1 && exit'
end

local function meson_buildandrun_cmd(root_dir, this_file)
  local build_dir = get_meson_build_dir(root_dir)
  local target = pick_meson_target(root_dir, build_dir, this_file)
  return
    wrap_cmd('ninja -C ' .. escape(build_dir) .. ' ' .. escape(target.name) .. ' && ' .. escape(target.path))
end

M.run = function()
  local fname = vim.api.nvim_buf_get_name(0)
  local cmd;
  if vim.b.f9 then
    cmd = vim.b.f9
  elseif vim.g.f9 then
    cmd = vim.g.f9
  elseif vim.fn.executable(fname) == 1 then
    cmd = wrap_cmd(escape(fname))
  else
    local clients = vim.lsp.buf_get_clients()
    if #clients > 0 then
      local root_dir = clients[1].config.root_dir
      if root_dir then
        local function isft(fts)
          return has(clients[1].config.filetypes, fts)
        end
        local function with_file(rel_path)
          return vim.fn.filereadable(root_dir .. '/' .. rel_path) == 1
        end
        if isft{'c', 'cpp'} and with_file 'meson.build' then
          cmd = meson_buildandrun_cmd(root_dir, fname)
        elseif isft{'javascript', 'typescript'} and with_file 'package.json' then
          cmd = wrap_cmd('npm --prefix ' .. escape(root_dir) .. ' start')
        end
      end
    end
  end
  if not cmd then
    local action = 'chmod +x ' .. escape(fname)
    cmd = 'history -c; clear; echo -n ' .. action .. '"? [y/N] "; ' ..
      'read -n1 ans; [ "$?" = 0 -a "$ans" = "" ] && ans=n || echo; ' ..
      'if [ "$ans" = "y" ]; then ' .. action .. ' && exit; else exit; fi'
  end
  require'toggleterm'.exec(cmd, nil, nil, nil, nil, nil, false, nil)
end

return M
