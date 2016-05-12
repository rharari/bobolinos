defmodule Data do
  require Record

  Record.defrecord :userRec, [id: nil, nick: nil, idAvatar: 0, x: 0, y: 0]

end