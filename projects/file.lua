--testing update


--File Manipution
if not fs.exists('/data') then
  fs.makeDir('/data')
end

function write(data, name, folder)
  if folder then 
    local f = fs.open('/'..folder..'/'..name, 'w')
    f.write(textutils.serialize(data))
    f.close()
  else
    local f = fs.open('/data/'..name, 'w')
    f.write(textutils.serialize(data))
    f.close()
  end
  
end

function read(name, folder)
  local data = nil
  if folder then
    if fs.exists('/'..folder..'/'..name) then
      local f = fs.open('/'..folder..'/'..name, 'r')
      data = textutils.unserialize(f.readAll())
      f.close()
    end
  else
    if fs.exists('/data/'..name) then
      local f = fs.open('/data/'..name, 'r')
      data = textutils.unserialize(f.readAll())
      f.close()
    end
  end

  return data
end
