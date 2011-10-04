river = require('../lib/river')

wait = jasmine.asyncSpecWait
done = jasmine.asyncSpecDone

expectUpdate = (expectedNewValues=null, expectedOldValues=null) ->
  (newValues, oldValues) ->
    expect(newValues).toEqual(expectedNewValues)
    expect(oldValues).toEqual(expectedOldValues)

expectUpdates = (expectedValues...) ->
  callCount = 0
  (newValues, oldValues) ->
    [expectedNewValues, expectedOldValues] = expectedValues[callCount]
    expect(newValues).toEqual(expectedNewValues)
    expect(oldValues).toEqual(expectedOldValues)
    callCount++
  

abc = { a:'a', b:'b', c:'c' }

describe "Query", ->
  it "Compiles 'select *' queries", ->
    ctx = river.createContext()
    ctx.addQuery 'SELECT * FROM data', expectUpdate([abc], null)
    ctx.push('data', abc)

  it "Compiles 'select a, b' queries", ->
    ctx = river.createContext()
    ctx.addQuery 'SELECT a, b FROM data', expectUpdate([{a:'a', b:'b'}], null)
    ctx.push('data', abc)

  it "Compiles 'select a AS 'c'' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT a AS c FROM data", expectUpdate([{c:'a'}], null)
    ctx.push('data', abc)

  it "Compiles 'select * WHERE' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT * FROM data WHERE foo = 1", expectUpdate([{foo:1}], null)
    ctx.push('data', foo:2)
    ctx.push('data', foo:1)

  it "Compiles 'LIKE' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT * FROM data WHERE foo LIKE '%bar%'",
      expectUpdates([[{foo:'xbarx'}], null], [[{foo:'zbarz'}], null])
    ctx.push('data', foo:'car')
    ctx.push('data', foo:'bar')
    ctx.push('data', foo:'xbarx')
    ctx.push('data', foo:'zbarz')

  it "Compiles 'select * WHERE AND' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT * FROM data WHERE foo = 1 AND bar = 2", expectUpdate([{foo:1, bar:2}], null)
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:1, bar:2)

  it "Compiles 'select * WHERE AND nested' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT * FROM data WHERE foo = 1 AND (bar = 2 OR foo = 1)", expectUpdate([{foo:1, bar:1}], null)
    ctx.push('data', foo:1, bar:1)
    
  it "Compiles 'select with limit' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT * FROM data LIMIT 1", expectUpdate([{foo:1, bar:1}], null)
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:2, bar:2)
    
  it "Compiles 'select with count(1)' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT COUNT(1) FROM data", 
      expectUpdates([[{'COUNT(1)':1}], null], [[{'COUNT(1)':2}], null])
    ctx.push('data', foo:'a', bar:1)
    ctx.push('data', foo:'b', bar:1)
    
  it "Compiles 'select with count(field)' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT COUNT(foo) AS foo_count FROM data", 
      expectUpdates([[{foo_count:2}], null], [[{foo_count:4}], null])
    ctx.push('data', foo:2, bar:1)
    ctx.push('data', foo:2, bar:1)
    
  it "Compiles 'select with min(field)' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT MIN(foo) AS foo_min FROM data", 
      expectUpdates([[{foo_min:3}], null], [[{foo_min:2}], null])
      # TODO: The expectation should actually be this, as it should include the old value too.
      # expectUpdates([[{foo_min:3}], null], [[{foo_min:2}], [{foo_min:3}]])
    ctx.push('data', foo:3)
    ctx.push('data', foo:4)
    ctx.push('data', foo:2)
    
  it "Compiles 'select DISTINCT' queries", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT DISTINCT foo FROM data",
      expectUpdates([[{foo:1}], null], [[{foo:2}], null])
    ctx.push('data', foo:1, bar:1)
    ctx.push('data', foo:1, bar:2)
    ctx.push('data', foo:2, bar:1)
  
  it "Compiles Functions", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT LENGTH(foo) as foo_l FROM data", expectUpdate([{foo_l:3}], null)
    ctx.push('data', foo:'bar')
  
  it "Compiles nested Functions", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT MAX(NUMBER(foo)) as bar FROM data", expectUpdate([{bar:3}], null)
    ctx.push('data', foo:'3')
  
  it "Compiles Functions in conditions", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT foo FROM data WHERE LENGTH(foo) > 2", expectUpdate([{foo:'yes'}], null)
    ctx.push('data', foo:'no')
    ctx.push('data', foo:'yes')
  
  it "Compiles IF conditions", ->
    ctx = river.createContext()
    ctx.addQuery "SELECT IF(foo, 1, 2) AS f FROM data", expectUpdate([{f:1}], null)
    ctx.push('data', foo:'yes')

  
  # it "Compiles 'select with group' queries", ->
  #   ctx = river.createContext()
  #   ctx.addQuery "SELECT foo, COUNT(1) FROM data GROUP BY foo", 
  #     expectUpdates([[{foo:'a', 'COUNT(1)':1}], null], [[{foo:'b', 'COUNT(1)':1}], null], [[{foo:'a', 'COUNT(1)':2}], null])
  #   ctx.push('data', foo:'a', bar:1)
  #   ctx.push('data', foo:'b', bar:1)
  #   ctx.push('data', foo:'a', bar:1)
    
    