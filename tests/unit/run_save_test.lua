local TestHelper = require('tests.test_helper')
local JsonCodec = require('src.core.json_codec')
local RunSave = require('src.core.run_save')
local Fixtures = require('tests.helpers.fixtures')

local suite = {}

local filesystem = nil
local storage = nil

function suite.before_each()
  storage = {}
  filesystem = {
    exists = function(_, path)
      return storage[path] ~= nil
    end,
    ensure_directory = function(_, path)
      storage.__dir = path
      return true
    end,
    read = function(_, path)
      if storage[path] == nil then
        return nil, 'missing'
      end
      return storage[path], nil
    end,
    write = function(_, path, content)
      storage[path] = content
      return true, nil
    end,
    remove = function(_, path)
      storage[path] = nil
      return true, nil
    end,
    rename = function(_, from_path, to_path)
      if storage[from_path] == nil then
        return false, 'missing'
      end
      storage[to_path] = storage[from_path]
      storage[from_path] = nil
      return true, nil
    end,
  }
  RunSave:set_filesystem(filesystem)
end

function suite.after_each()
  RunSave:set_filesystem(nil)
end

function suite.test_write_load_and_clear_roundtrip()
  local payload = {
    version = 2,
    checkpoint = {
      kind = 'combat_start',
    },
    systems = {
      hero = {
        level = 3,
      },
    },
  }

  local ok, err = RunSave:write(payload)
  TestHelper.assert_true(ok, '세이브 파일이 정상적으로 작성되어야 합니다.')
  TestHelper.assert_equal(err, nil)
  TestHelper.assert_true(RunSave:exists(), '세이브 존재 여부가 true여야 합니다.')
  TestHelper.assert_true(storage['saves/active_run.json'] ~= nil, 'JSON 세이브 파일이 생성되어야 합니다.')
  TestHelper.assert_false(string.find(storage['saves/active_run.json'], 'return ', 1, true) ~= nil)

  local envelope, decode_err = JsonCodec.decode(storage['saves/active_run.json'])
  TestHelper.assert_equal(decode_err, nil)
  TestHelper.assert_equal(envelope.format_version, 1)
  TestHelper.assert_equal(envelope.payload.checkpoint.kind, 'combat_start')

  local loaded, load_err = RunSave:load()
  TestHelper.assert_equal(load_err, nil)
  TestHelper.assert_equal(loaded.version, 2)
  TestHelper.assert_equal(loaded.checkpoint.kind, 'combat_start')
  TestHelper.assert_equal(loaded.systems.hero.level, 3)

  local cleared, clear_err = RunSave:clear()
  TestHelper.assert_true(cleared, '세이브 삭제가 성공해야 합니다.')
  TestHelper.assert_equal(clear_err, nil)
  TestHelper.assert_false(RunSave:exists(), '세이브 삭제 후 존재 여부가 false여야 합니다.')
end

function suite.test_load_falls_back_to_backup_when_primary_is_corrupted()
  local payload = {
    version = 2,
    checkpoint = {
      kind = 'event_start',
    },
    systems = {
      mana = {
        current_mana = 80,
        max_mana = 100,
        reserved_mana = 0,
      },
    },
  }

  local ok = RunSave:write(payload)
  TestHelper.assert_true(ok)
  storage['saves/active_run.bak'] = storage['saves/active_run.json']
  storage['saves/active_run.json'] = '{"format_version":1,"checksum":"deadbeef","payload":{"version":2}}'

  local loaded, load_err = RunSave:load()
  TestHelper.assert_equal(load_err, nil)
  TestHelper.assert_equal(loaded.checkpoint.kind, 'event_start')
  TestHelper.assert_equal(loaded.systems.mana.current_mana, 80)
end

function suite.test_write_accepts_spell_book_snapshot_with_serialized_effects()
  local fixture = Fixtures.create_reward_fixture(404)
  local payload = {
    version = 2,
    checkpoint = {
      kind = 'start_node_select',
    },
    systems = {
      spell_book = fixture.spell_book:snapshot(),
    },
  }

  local ok, err = RunSave:write(payload)
  TestHelper.assert_true(ok, '주문 effect가 JSON 직렬화 가능한 형태여야 합니다.')
  TestHelper.assert_equal(err, nil)

  local envelope, decode_err = JsonCodec.decode(storage['saves/active_run.json'])
  TestHelper.assert_equal(decode_err, nil)
  TestHelper.assert_equal(type(envelope.payload.systems.spell_book.spells[1].effect.apply), 'nil')
  TestHelper.assert_true(type(envelope.payload.systems.spell_book.spells[1].effect.type) == 'string')
end

return suite
