--
-- This file contains examples on how IMAPFilter can be extended using
-- the Lua programming language.
--


-- IMAPFilter can be detached from the controlling terminal and run in
-- the background as a system daemon.
--
-- The auxiliary function daemon_mode() is supplied for conveniency.
-- The following example puts imapfilter in the background and runs
-- endlessly, executing the commands in the forever() function and
-- sleeping for 600 seconds between intervals:

function forever()
    results = myaccount.mymailbox:is_old()
    results:move_messages(myaccount.archive)
end

become_daemon(600, forever)


-- IMAPFilter can take advantage of all those filtering utilities that
-- are available and use a wide range of heuristic tests, text analysis,
-- internet-based realtime blacklists, advanced learning algorithms,
-- etc. to classify mail.  IMAPFilter can pipe a message to a program
-- and act on the message based on the program's exit status.
--
-- The auxiliary function pipe_to() is supplied for conveniency.  For
-- example if there was a utility named "bayesian-spam-filter", which
-- returned 1 when it considered the message "spam" and 0 otherwise:

all = myaccount.mymailbox:select_all()

results = Set {}
for _, mesg in ipairs(all) do
    mbox, uid = unpack(mesg)
    text = mbox[uid]:fetch_message()
    if (pipe_to('bayesian-spam-filter', text) == 1) then
        table.insert(results, mesg)
    end
end

results:delete_messages()


-- One might want to run the bayesian filter only in those parts (attachments)
-- of the message that are of type text/plain and smaller than 1024 bytes.
-- This is possible using the fetch_structure() and fetch_part() functions:

all = myaccount.mymailbox:select_all()

results = Set {}
for _, mesg in ipairs(all) do
    mbox, uid = unpack(mesg)
    structure = mbox[uid]:fetch_structure()
    for partid, partinf in pairs(structure) do
        if partinf.type:lower() == 'text/plain' and partinf.size < 1024 then
            part = mbox[uid]:fetch_part(partid)
            if (pipe_to('bayesian-spam-filter', part) == 1) then
                table.insert(results, mesg)
                break
            end
        end
    end
end

results:delete_messages()


-- Passwords could be extracted during execution time from an encrypted
-- file.
--
-- The file is encrypted using the openssl(1) command line tool.  For
-- example the "passwords.txt" file:
--
--   secret1 secret2
--
-- ... is encrypted and saved to a file named "passwords.enc" with the
-- command:
--
--   $ openssl bf -salt -in passwords.txt -out passwords.enc
--
-- The auxiliary function pipe_from() is supplied for conveniency.  The
-- user is prompted to enter the decryption password, the file is
-- decrypted and the account passwords are set accordingly:

status, output = pipe_from('openssl bf -d -salt -in ~/passwords.enc')

_, _, password1, password2 = string.find(output, '([%w%p]+)\n([%w%p]+)\n')

account1 = IMAP {
    server = 'imap1.mail.server',
    username = 'user1',
    password = password1
}

account2 = IMAP {
    server = 'imap2.mail.server',
    username = 'user2',
    password = password2
}

