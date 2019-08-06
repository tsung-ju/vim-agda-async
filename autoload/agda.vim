function agda#reset_syntax()
  syntax clear
  runtime syntax/agda.vim
endfunction

function agda#reload_syntax()
  call agda#reset_syntax()
  let l:path = expand('%:h') . '/.' . expand('%:t') . '.vim'
  if filereadable(l:path)
    exec 'source ' . escape(l:path, '*')
  endif
endfunction

function agda#load()
  call s:send_command('(Cmd_load ' . json_encode(expand('%')) . ' [])')
endfunction

function agda#compile()
  call s:send_command('(Cmd_compile MAlonzo ' . json_encode(expand('%')) . ' [])')
endfunction

function agda#constraints()
  call s:send_command('(Cmd_constraints)')
endfunction

function agda#metas()
  call s:send_command('(Cmd_metas)')
endfunction

function agda#give(use_force)
  call s:goal_command(['Cmd_give', a:use_force])
endfunction

function agda#refine()
  call s:goal_command(['Cmd_refine_or_intro', 'False'])
endfunction

function s:goal_command(cmd)
  let l:goals = agda#goal#get_all(bufnr('%'))
  let l:goal_index = agda#goal#find_current(l:goals)

  if l:goal_index == -1
    echoerr 'For this command, please place the cursor in a goal'
    return
  endif

  let l:goal_name = b:agda_ctx.interaction_points[l:goal_index]

  let l:goal_body = agda#goal#get_body(goals[l:goal_index])

  let l:cmd = a:cmd + [
    \ l:goal_name,
    \ 'noRange',
    \ json_encode(l:goal_body) ]
  call s:send_command('(' . join(l:cmd) . ')')
endfunction

function s:start_agda()
  if !exists('b:agda_ctx')
    let l:ctx = {}
    let l:ctx.buf = bufnr('%')
    let l:ctx.interaction_points = []
    let l:ctx.job = job_start(
      \ ['agda', '--vim', '--interaction-json'],
      \ {'out_cb': function('s:handle_response', [l:ctx])})
    let l:ctx.ch = job_getchannel(l:ctx.job)
    let b:agda_ctx = l:ctx
  endif
endfunction

function s:stop_agda()
  if exists('b:agda_ctx')
    call jobstop(b:agda_ctx)
    unlet b:agda_ctx
  endif
endfunction

function s:send_command(interatcion)
  let l:args = [
    \ 'IOTCM',
    \ json_encode(expand('%')),
    \ 'NonInteractive',
    \ 'Direct',
    \ a:interatcion ]

  call s:start_agda()

  call ch_sendraw(b:agda_ctx.ch, join(l:args) . "\n")
endfunction

function s:handle_response(ctx, ch, msg)
  let l:msg = s:parse_response(a:msg)
  if l:msg.kind !=# 'HighlightingInfo'
    echom l:msg.kind
    echom string(l:msg)
  endif
  if has_key(s:handler, l:msg.kind)
    call s:handler[l:msg.kind](a:ctx, l:msg)
  endif
endfunction

function s:parse_response(msg)
  return json_decode(substitute(a:msg, '^JSON> ', '', ''))
endfunction

let s:handler = {}
function s:handler.Status(ctx, msg)
  if a:ctx.buf == bufnr('%')
    call agda#reload_syntax()
  endif
endfunction

function s:handler.RunningInfo(ctx, msg)
  for l:line in split(a:msg.message, "\n")
    echom l:line
  endfor
endfunction

function s:handler.ClearHighlighting(ctx, msg)
  if a:ctx.buf == bufnr('%')
    call agda#reset_syntax()
  endif
  cclose
  call setqflist([], 'r')
endfunction

function s:handler.InteractionPoints(ctx, msg)
  let a:ctx.interaction_points = a:msg.interactionPoints
endfunction

let s:error_atoms = [
  \ 'error',
  \ 'unsolvedmeta',
  \ 'unsolvedconstraint',
  \ 'terminationproblem',
  \ 'deadcode',
  \ 'coverageproblem',
  \ 'positivityproblem',
  \ 'incompletepattern',
  \ 'catchallclause',
  \ 'confluenceproblem',
\ ]

function s:handler.HighlightingInfo(ctx, msg)
  let l:inited = 0
  let l:buf = a:ctx.buf

  for l:item in a:msg.info.payload
    for l:atom in l:item.atoms
      if index(s:error_atoms, l:atom) == -1
        continue
      endif

      if !l:inited
        let l:lines = getbufline(l:buf, 1, '$')
        let l:line_starts = s:line_starts(l:lines)
        let l:inited = 1
      endif

      if has_key(l:item, 'note') && l:item.note != v:null
        let l:text = l:item.note
      else
        let l:text = l:atom
      endif

      let l:start = l:item.range[0]
      let [l:lnum, l:col] = s:chars2pos(l:lines, l:line_starts, l:start)
      call setqflist([{
        \ 'bufnr': l:buf,
        \ 'lnum': l:lnum,
        \ 'col': l:col,
        \ 'text': l:text,
      \ }], 'a')

      break
    endfor
  endfor
endfunction

function s:line_starts(lines)
  let l:line_starts = []
  let l:acc = 1
  for l:line in a:lines
    call add(l:line_starts, l:acc)
    let acc += strchars(l:line) + 1
  endfor
  return l:line_starts
endfunction

function s:chars2pos(lines, line_starts, chars)
  let l:lnum = 0
  for l:line_start in a:line_starts
    if l:line_start > a:chars
      break
    else
      let l:lnum += 1
    endif
  endfor
  let l:charcol = a:chars - a:line_starts[l:lnum - 1] + 1
  let l:col = strlen(strcharpart(a:lines[l:lnum - 1], 0, l:charcol))
  return [l:lnum, l:col]
endfunction

function s:handler.GiveAction(ctx, msg)
  let l:goal_index = index(a:ctx.interaction_points, a:msg.interactionPoint)
  if l:goal_index != -1
    let l:goal = agda#goal#get_all(a:ctx.buf)[l:goal_index]
    call agda#goal#set_body(a:ctx.buf, l:goal, a:msg.giveResult)
  endif
endfunction
