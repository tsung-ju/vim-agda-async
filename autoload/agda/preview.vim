" Copyright (C) 2020  ray851107
"
" This file is part of vim-agda-async.
"
" vim-agda-async is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" vim-agda-async is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with vim-agda-async.  If not, see <https://www.gnu.org/licenses/>.

let s:info_formatters = {}

function agda#preview#display_info(info)
  if has_key(s:info_formatters, a:info.kind)
    let [l:title, l:body] = s:info_formatters[a:info.kind](a:info)
    call s:show_preview(l:title, l:body)
  else
    call s:show_preview('*Info (' . a:info.kind . ')*', string(a:info))
  endif
endfunction

function s:show_preview(title, body)
  execute 'silent belowright noswapfile pedit ' . fnameescape(tempname())
  wincmd P
  setlocal buftype=nofile nobuflisted bufhidden=wipe nonumber norelativenumber signcolumn=no modifiable
  call setline(1, split(a:body, "\n"))
  setlocal nomodified nomodifiable
  let &l:statusline = a:title . ' %w'
  wincmd p
endfunction

function s:info_formatters.Error(info)
  return ['*Error*', a:info.message]
endfunction

function s:info_formatters.AllGoalsWarnings(info)
  let l:has_goal = !empty(a:info.visibleGoals)
  let l:has_error = !empty(a:info.errors)
  let l:has_warning = !empty(a:info.warnings)

  if !l:has_goal && !l:has_error &&!l:has_warning
    return ['*All Done*', '']
  endif

  let l:title_parts = []
  let l:body_parts = []

  if l:has_goal
    let l:goals = map(copy(a:info.visibleGoals), {_, val -> s:format_constraint(val)})
    call add(l:title_parts, 'Goals')
    call add(l:body_parts, "Goals\n" . join(l:goals, "\n") . "\n")
  endif

  if l:has_error
    call add(l:title_parts, 'Errors')
    call add(l:body_parts, "Errors\n" . a:info.errors)
  endif

  if l:has_warning
    call add(l:title_parts, 'Warnings')
    call add(l:body_parts, "Warnings\n" . a:info.warnings)
  endif

  let l:title = '*All ' . join(l:title_parts, ', ') . '*'
  let l:body = join(l:body_parts, "\n")
  return [l:title, l:body]
endfunction

function s:info_formatters.Context(info)
  let l:entries = map(copy(a:info.context), function("s:format_context_entry"))
  return ['*Context*', join(l:entries, "\n")]
endfunction

let s:goal_info_formatters = {}

function s:info_formatters.GoalSpecific(info)
  if has_key(s:goal_info_formatters, a:info.goalInfo.kind)
    return s:goal_info_formatters[a:info.goalInfo.kind](a:info.goalInfo)
  else
    return ['*GoalInfo (' . a:goal_info.kind . ')*', string(a:goal_info)]
  endif
endfunction

function s:goal_info_formatters.CurrentGoal(goal_info)
  return ['*Current Goal*', 'Goal : ' . a:goal_info.type]
endfunction

function s:goal_info_formatters.GoalType(goal_info)
  let l:entries = map(copy(a:goal_info.entries), function("s:format_context_entry"))
  let l:body = 'Goal : ' . a:goal_info.type . repeat('-', 80) . join(l:entries, "\n")
  return ['*Goal Type etc.*', l:body]
endfunction

function s:format_constraint(constraint)
  if a:constraint.kind ==# 'OfType'
    return '?' . a:constraint.constraintObj . ' : ' . a:constraint.type
  else
    return string(a:constraint)
  endif
endfunction

function s:format_context_entry(entry)
  let l:name = a:entry.inScope && a:entry.originalName !=# a:entry.reifiedName
    \ ? a:entry.originalName . ' = ' . a:entry.reifiedName
    \ : a:entry.reifiedName

  let l:attributes = a:entry.inScope ? '' : '   (not in scope)'

  return l:name . ' : ' . a:entry.binding . l:attributes
endfunction
