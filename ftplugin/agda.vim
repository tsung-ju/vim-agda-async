function s:map(key, cmd, arg='')
  execute 'nnoremap <buffer><silent> <localleader>' . a:key . ' :call agda#' . a:cmd . '(' . a:arg . ')<cr>'
endfunction

function s:map_u(key, cmd, options)
  for l:count in range(len(a:options))
    let l:key = repeat('u', l:count) . a:key
    call s:map(l:key, a:cmd, "'" . a:options[l:count] . "'")
  endfor
endfunction

function s:map_normalise(key, cmd)
  call s:map_u(a:key, a:cmd, ['Simplified', 'Instantiated', 'Normalised'])
endfunction

call s:map('l', 'load')
call s:map('xc', 'compile')
call s:map('xr', 'restart')
call s:map('xa', 'abort')
call s:map('xh', 'toggle_implicit_args')
call s:map('=', 'constraints')
call s:map('?', 'metas')

call s:map_u('<space>', 'give', ['WithoutForce', 'WithForce'])
call s:map_normalise('m', 'elaborate_give')
call s:map_u('r', 'refine_or_intro', ['False', 'True'])
call s:map('a', 'auto_maybe_all')
call s:map('c', 'make_case')
call s:map_normalise('t', 'goal_type')
call s:map_normalise('e', 'context')
call s:map_normalise('h', 'helper_function')
call s:map_normalise('d', 'infer_maybe_toplevel')
call s:map_normalise('w', 'why_in_scope_maybe_toplevel')
call s:map_normalise(',', 'goal_type_context')
call s:map_normalise('.', 'goal_type_context_infer')
call s:map_normalise(';', 'goal_type_context_check')
call s:map_normalise('z', 'search_about_toplevel')
call s:map_normalise('o', 'show_module_contents_maybe_toplevel')
call s:map_u('n', 'compute_maybe_toplevel', ['DefaultCompute', 'IgnoreAbstract'])

nnoremap <buffer><silent> ]g :call agda#goal#go_next()<cr>
nnoremap <buffer><silent> [g :call agda#goal#go_prev()<cr>

call agda#load()
