window.plugins.method =
  emit: (div, item) ->
  bind: (div, item) ->

    data = []
    input = {}
    output = {}

    div.addClass 'radar-source'
    div.get(0).radarData = -> output
    div.mousemove (e) -> $(div).triggerHandler('thumb', $(e.target).text())

    # http://stella.laurenzo.org/2011/03/bulletproof-node-js-coding/

    # attach = (search,callback = ->) ->
    #   for elem in wiki.getDataNodes div
    #     if (source = $(elem).data('item')).text.indexOf(search) >= 0
    #       new_data = _.select source.data, (row) -> row.Activity?
    #       return callback new_data
    #   $.get "/data/#{search}", (page) ->
    #     throw new Error "can't find dataset '#{s}'" unless page
    #     for obj in page.story
    #       if obj.type == 'data' && obj.text? && obj.text.indexOf(search) >= 0
    #         new_data = _.select obj.data, (row) -> row.Activity?
    #         return callback new_data
    #     throw new Error "can't find dataset '#{s}' in '#{page.title}'"


    # query = (s) ->
    #   keys = $.trim(s).split ' '
    #   choices = data
    #   for k in keys
    #     next if k == ' '
    #     n = choices.length
    #     choices = _.select choices, (row) ->
    #       row.Activity.indexOf(k) >= 0 || row.Category.indexOf(k) >= 0
    #     throw new Error "Can't find #{k} in remaining #{n} choices" if choices.length == 0
    #   choices

    sum = (v) ->
      _.reduce v, (s,n) -> s += n

    avg = (v) ->
      sum(v)/v.length

    round = (n) ->
      return '?' unless n?
      if n.toString().match /\.\d\d\d/
        n.toFixed 2
      else
        n

    annotate = (text) ->
      return '' unless text?
      " <span title=\"#{text}\">*</span>"

    calculate = (item) ->
      list = []
      allocated = 0
      lines = item.text.split "\n"
      report = []

      dispatch = (list, allocated, lines, report, done) ->
        color = '#eee'
        value = comment = null
        hours = ''
        line = lines.shift()
        return done report unless line?

        next_dispatch = ->
          list.push +value if value? and ! isNaN +value
          report.push "<tr style=\"background:#{color};\"><td style=\"width: 20%;\"><b>#{round value}</b><td>#{line}#{annotate comment}"
          dispatch list, allocated, lines, report, done

        apply = (name, list) ->
          if name == 'SUM'
            color = '#ddd'
            sum(list)
          else if name == 'AVG'
            color = '#ddd'
            avg(list)
          else
            color = '#edd'

        try
          if args = line.match /^USE ([\w ]+)$/
            color = '#ddd'
            value = ' '
            return attach (line = args[1]), (new_data) ->
              data = new_data
              next_dispatch()
          else if args = line.match /^(-?[0-9.]+) ([\w ]+)$/
            result = hours = +args[1]
            line = args[2]
            output[line] = value = result
          else if args = line.match /^([A-Z]+) ([\w ]+)$/
            [value, list] = [apply(args[1], list), []]
            line = args[2]
            output[line] = value
          else if args = line.match /^([A-Z]+)$/
            [value, list] = [apply(args[1], list), []]
          else if input[line]?
            value = input[line]
            comment = input["#{line} Assumptions"] || null
          else if line.match /^[0-9\.-]+$/
            value = +line
          else
            color = '#edd'
        catch err
          color = '#edd'
          value = null
          comment = err.message
        return next_dispatch()

      dispatch list, allocated, lines, report, (report) ->
        text = report.join "\n"
        table = $('<table style="width:100%; background:#eee; padding:.8em;"/>').html text
        div.append table
        div.dblclick -> wiki.textEditor div, item

    calculate item