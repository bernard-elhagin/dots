" Codex integration for Vim's built-in terminal.
if exists('g:loaded_codex_vim') || !has('terminal')
    finish
endif
let g:loaded_codex_vim = 1

function! s:ProjectRoot() abort
    let l:file = expand('%:p')
    let l:start = empty(l:file) ? getcwd() : fnamemodify(l:file, ':h')

    " Handle both ordinary repositories and worktrees, where .git is a file.
    let l:git_dir = finddir('.git', l:start . ';')
    if !empty(l:git_dir)
        return fnamemodify(l:git_dir, ':p:h')
    endif

    let l:git_file = findfile('.git', l:start . ';')
    if !empty(l:git_file)
        return fnamemodify(l:git_file, ':p:h')
    endif

    return l:start
endfunction

function! s:OpenTerminal(args, finish, height) abort
    let l:codex = exepath('codex')
    if empty(l:codex)
        echoerr 'Codex CLI was not found in PATH'
        return
    endif

    let l:root = s:ProjectRoot()
    let l:argv = [l:codex] + a:args

    execute 'botright ' . a:height . 'new'
    call term_start(l:argv, {
                \ 'curwin': 1,
                \ 'cwd': l:root,
                \ 'term_finish': a:finish,
                \ })
    startinsert
endfunction

function! s:Codex(prompt) abort
    let l:args = empty(a:prompt) ? [] : [a:prompt]
    call s:OpenTerminal(l:args, 'close', 15)
endfunction

function! s:CodexAsk(prompt) abort
    call s:OpenTerminal(['exec', a:prompt], 'open', 12)
endfunction

function! s:CodexReview() abort
    call s:OpenTerminal(['exec', 'review'], 'open', 15)
endfunction

command! -nargs=? Codex call <SID>Codex(<q-args>)
command! -nargs=+ CodexAsk call <SID>CodexAsk(<q-args>)
command! -nargs=0 CodexReview call <SID>CodexReview()
