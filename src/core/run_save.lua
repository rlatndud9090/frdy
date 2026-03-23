local JsonCodec = require('src.core.json_codec')

---@class RunSaveFilesystem
---@field exists fun(self: RunSaveFilesystem, path: string): boolean
---@field ensure_directory fun(self: RunSaveFilesystem, path: string): boolean
---@field read fun(self: RunSaveFilesystem, path: string): string|nil, string|nil
---@field write fun(self: RunSaveFilesystem, path: string, content: string): boolean, string|nil
---@field remove fun(self: RunSaveFilesystem, path: string): boolean, string|nil
---@field rename fun(self: RunSaveFilesystem, from_path: string, to_path: string): boolean, string|nil

---@class RunSave
local RunSave = {}

local SAVE_DIR = 'saves'
local SAVE_PATH = SAVE_DIR .. '/active_run.json'
local TMP_PATH = SAVE_DIR .. '/active_run.tmp'
local BACKUP_PATH = SAVE_DIR .. '/active_run.bak'
local LEGACY_SAVE_PATH = SAVE_DIR .. '/active_run.lua'
local FORMAT_VERSION = 1

---@type RunSaveFilesystem|nil
RunSave._filesystem = nil

---@param content string
---@return string
local function compute_checksum(content)
  local a = 1
  local b = 0
  for index = 1, #content do
    a = (a + string.byte(content, index)) % 65521
    b = (b + a) % 65521
  end
  return string.format('%04x%04x', a, b)
end

---@return RunSaveFilesystem
local function create_love_filesystem()
  return {
    exists = function(_, path)
      return love.filesystem.getInfo(path) ~= nil
    end,
    ensure_directory = function(_, path)
      if path == '' then
        return true
      end
      return love.filesystem.createDirectory(path)
    end,
    read = function(_, path)
      local content = love.filesystem.read(path)
      if content == nil then
        return nil, '세이브 파일을 읽지 못했습니다: ' .. path
      end
      return content, nil
    end,
    write = function(_, path, content)
      local ok, err = love.filesystem.write(path, content)
      if not ok then
        return false, err or '세이브 파일을 쓰지 못했습니다.'
      end
      return true, nil
    end,
    remove = function(_, path)
      if not love.filesystem.getInfo(path) then
        return true, nil
      end
      local ok, err = love.filesystem.remove(path)
      if not ok then
        return false, err or '세이브 파일을 삭제하지 못했습니다.'
      end
      return true, nil
    end,
    rename = function(_, from_path, to_path)
      local save_dir = love.filesystem.getSaveDirectory()
      local ok, err = os.rename(save_dir .. '/' .. from_path, save_dir .. '/' .. to_path)
      if not ok then
        return false, tostring(err or '세이브 파일 이름을 변경하지 못했습니다.')
      end
      return true, nil
    end,
  }
end

---@return RunSaveFilesystem
local function create_native_filesystem()
  return {
    exists = function(_, path)
      local handle = io.open(path, 'r')
      if handle then
        handle:close()
        return true
      end
      return false
    end,
    ensure_directory = function(_, path)
      if path == '' then
        return true
      end
      local ok = os.execute(string.format('mkdir -p %q', path))
      return ok == true or ok == 0
    end,
    read = function(_, path)
      local handle, err = io.open(path, 'r')
      if not handle then
        return nil, err or '세이브 파일을 읽지 못했습니다.'
      end
      local content = handle:read('*a')
      handle:close()
      return content, nil
    end,
    write = function(_, path, content)
      local handle, err = io.open(path, 'w')
      if not handle then
        return false, err or '세이브 파일을 쓰지 못했습니다.'
      end
      handle:write(content)
      handle:close()
      return true, nil
    end,
    remove = function(_, path)
      local handle = io.open(path, 'r')
      if handle then
        handle:close()
      else
        return true, nil
      end
      local ok, err = os.remove(path)
      if not ok then
        return false, err or '세이브 파일을 삭제하지 못했습니다.'
      end
      return true, nil
    end,
    rename = function(_, from_path, to_path)
      local ok, err = os.rename(from_path, to_path)
      if not ok then
        return false, tostring(err or '세이브 파일 이름을 변경하지 못했습니다.')
      end
      return true, nil
    end,
  }
end

---@return RunSaveFilesystem
function RunSave:_get_filesystem()
  if self._filesystem then
    return self._filesystem
  end

  if love and love.filesystem then
    self._filesystem = create_love_filesystem()
  else
    self._filesystem = create_native_filesystem()
  end

  return self._filesystem
end

---@param filesystem RunSaveFilesystem|nil
---@return nil
function RunSave:set_filesystem(filesystem)
  self._filesystem = filesystem
end

---@return string
function RunSave:get_path()
  return SAVE_PATH
end

---@return boolean
function RunSave:exists()
  local filesystem = self:_get_filesystem()
  return filesystem:exists(SAVE_PATH)
    or filesystem:exists(BACKUP_PATH)
end

---@param content string
---@return table|nil
---@return string|nil
function RunSave:_decode_json_payload(content)
  local envelope, decode_err = JsonCodec.decode(content)
  if type(envelope) ~= 'table' then
    return nil, decode_err or '세이브 파일 형식이 올바르지 않습니다.'
  end

  local version = tonumber(envelope.format_version)
  if version ~= FORMAT_VERSION then
    return nil, '지원하지 않는 세이브 포맷 버전입니다.'
  end

  if type(envelope.payload) ~= 'table' then
    return nil, '세이브 payload 형식이 올바르지 않습니다.'
  end

  local payload_json, encode_err = JsonCodec.encode(envelope.payload)
  if not payload_json then
    return nil, encode_err or '세이브 payload 직렬화에 실패했습니다.'
  end

  local expected_checksum = compute_checksum(payload_json)
  if envelope.checksum ~= expected_checksum then
    return nil, '세이브 checksum 검증에 실패했습니다.'
  end

  return envelope.payload, nil
end

---@param path string
---@return table|nil
---@return string|nil
---@return string|nil
function RunSave:_load_json_at_path(path)
  local filesystem = self:_get_filesystem()
  if not filesystem:exists(path) then
    return nil, '세이브 파일이 없습니다.', nil
  end

  local content, read_err = filesystem:read(path)
  if not content then
    return nil, read_err, nil
  end

  local payload, decode_err = self:_decode_json_payload(content)
  if not payload then
    return nil, decode_err, nil
  end

  return payload, nil, content
end

---@param content string
---@return boolean
---@return string|nil
function RunSave:_promote_backup_to_primary(content)
  local filesystem = self:_get_filesystem()
  if not filesystem:ensure_directory(SAVE_DIR) then
    return false, '세이브 디렉터리를 생성하지 못했습니다.'
  end

  filesystem:remove(TMP_PATH)
  local wrote, write_err = filesystem:write(TMP_PATH, content)
  if not wrote then
    filesystem:remove(TMP_PATH)
    return false, write_err
  end

  local removed, remove_err = filesystem:remove(SAVE_PATH)
  if not removed then
    filesystem:remove(TMP_PATH)
    return false, remove_err
  end

  local moved, move_err = filesystem:rename(TMP_PATH, SAVE_PATH)
  if not moved then
    filesystem:remove(TMP_PATH)
    return false, move_err
  end

  return true, nil
end

---@param payload table
---@return boolean
---@return string|nil
function RunSave:write(payload)
  local filesystem = self:_get_filesystem()
  if not filesystem:ensure_directory(SAVE_DIR) then
    return false, '세이브 디렉터리를 생성하지 못했습니다.'
  end

  local payload_json, payload_err = JsonCodec.encode(payload)
  if not payload_json then
    return false, payload_err or '세이브 payload를 인코딩하지 못했습니다.'
  end

  local content, encode_err = JsonCodec.encode({
    format_version = FORMAT_VERSION,
    checksum = compute_checksum(payload_json),
    payload = payload,
  })
  if not content then
    return false, encode_err or '세이브 envelope을 인코딩하지 못했습니다.'
  end

  filesystem:remove(TMP_PATH)
  local wrote, write_err = filesystem:write(TMP_PATH, content)
  if not wrote then
    filesystem:remove(TMP_PATH)
    return false, write_err
  end

  if filesystem:exists(BACKUP_PATH) then
    filesystem:remove(BACKUP_PATH)
  end

  local had_primary = filesystem:exists(SAVE_PATH)
  if had_primary then
    local moved_old, move_old_err = filesystem:rename(SAVE_PATH, BACKUP_PATH)
    if not moved_old then
      filesystem:remove(TMP_PATH)
      return false, move_old_err
    end
  end

  local moved_new, move_new_err = filesystem:rename(TMP_PATH, SAVE_PATH)
  if not moved_new then
    filesystem:remove(TMP_PATH)
    if had_primary and filesystem:exists(BACKUP_PATH) then
      filesystem:rename(BACKUP_PATH, SAVE_PATH)
    end
    return false, move_new_err
  end

  filesystem:remove(LEGACY_SAVE_PATH)
  return true, nil
end

---@return table|nil
---@return string|nil
function RunSave:load()
  local filesystem = self:_get_filesystem()
  local errors = {}
  local primary_payload, primary_err = self:_load_json_at_path(SAVE_PATH)
  if primary_payload then
    return primary_payload, nil
  end
  if primary_err then
    errors[#errors + 1] = primary_err
  end

  local backup_payload, backup_err, backup_content = self:_load_json_at_path(BACKUP_PATH)
  if backup_payload then
    if backup_content and (primary_err or not filesystem:exists(SAVE_PATH)) then
      local promoted, promote_err = self:_promote_backup_to_primary(backup_content)
      if not promoted and promote_err then
        print(promote_err)
      end
    end

    return backup_payload, nil
  end
  if backup_err then
    errors[#errors + 1] = backup_err
  end

  if filesystem:exists(LEGACY_SAVE_PATH) then
    errors[#errors + 1] = '레거시 Lua 세이브는 안전상 자동 로드하지 않습니다.'
  end

  return nil, table.concat(errors, ' / ')
end

---@return boolean
---@return string|nil
function RunSave:clear()
  local filesystem = self:_get_filesystem()
  local paths = {
    SAVE_PATH,
    TMP_PATH,
    BACKUP_PATH,
    LEGACY_SAVE_PATH,
  }

  for _, path in ipairs(paths) do
    local ok, err = filesystem:remove(path)
    if not ok then
      return false, err
    end
  end

  return true, nil
end

return RunSave
