import { useEffect, useState, useRef, FormEvent } from 'react';
import AppShell from '@/components/AppShell';
import { api, getUser } from '@/lib/api';

const initials = (name: string) =>
  (name || '?').split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase();

const fmtTime = (d: string) =>
  d ? new Date(d).toLocaleTimeString('en-BD', { hour: '2-digit', minute: '2-digit' }) : '';

export default function ChatPage() {
  const user = getUser();
  const [groups, setGroups] = useState<any[]>([]);
  const [selectedGroup, setSelectedGroup] = useState<any>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [message, setMessage] = useState('');
  const [loadingGroups, setLoadingGroups] = useState(true);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');
  const [showNewGroup, setShowNewGroup] = useState(false);
  const [groupName, setGroupName] = useState('');
  const [groupErr, setGroupErr] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const pollRef = useRef<NodeJS.Timer | null>(null);

  const loadGroups = async () => {
    try {
      const res = await api<any>('/api/chat/groups');
      setGroups(Array.isArray(res) ? res : res?.data ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setLoadingGroups(false); }
  };

  const loadMessages = async (groupId: string) => {
    setLoadingMessages(true);
    try {
      const res = await api<any>(`/api/chat/groups/${groupId}/messages`);
      setMessages(Array.isArray(res) ? res : res?.data ?? res?.messages ?? []);
    } catch { /* ignore */ }
    finally { setLoadingMessages(false); }
  };

  const pollMessages = async (groupId: string) => {
    try {
      const res = await api<any>(`/api/chat/groups/${groupId}/messages`);
      const msgs = Array.isArray(res) ? res : res?.data ?? res?.messages ?? [];
      setMessages((prev) => {
        if (msgs.length !== prev.length) return msgs;
        return prev;
      });
    } catch { /* ignore */ }
  };

  useEffect(() => { loadGroups(); }, []);

  useEffect(() => {
    if (selectedGroup) {
      loadMessages(selectedGroup.id);
      if (pollRef.current) clearInterval(pollRef.current as unknown as number);
      pollRef.current = setInterval(() => pollMessages(selectedGroup.id), 5000);
    } else {
      if (pollRef.current) clearInterval(pollRef.current as unknown as number);
    }
    return () => { if (pollRef.current) clearInterval(pollRef.current as unknown as number); };
  }, [selectedGroup]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const selectGroup = (g: any) => { setSelectedGroup(g); setMessages([]); };

  const sendMessage = async (e: FormEvent) => {
    e.preventDefault();
    if (!message.trim() || !selectedGroup) return;
    setSending(true);
    try {
      await api(`/api/chat/groups/${selectedGroup.id}/messages`, { method: 'POST', body: { body: message } });
      setMessage('');
      await loadMessages(selectedGroup.id);
    } catch (e: any) { alert(e.message); }
    finally { setSending(false); }
  };

  const createGroup = async (e: FormEvent) => {
    e.preventDefault();
    if (!groupName.trim()) { setGroupErr('Group name required'); return; }
    setGroupErr('');
    try {
      const g = await api<any>('/api/chat/groups', { method: 'POST', body: { name: groupName } });
      setShowNewGroup(false);
      setGroupName('');
      await loadGroups();
      if (g?.id) setSelectedGroup(g);
    } catch (e: any) { setGroupErr(e.message); }
  };

  const isMyMessage = (msg: any) => msg.senderId === user?.id || msg.userId === user?.id || msg.user?.id === user?.id;

  return (
    <AppShell>
      <div className="chat-layout" style={{ height: 'calc(100vh - 40px)' }}>
        {/* Sidebar */}
        <div className="chat-sidebar" style={{ display: 'flex', flexDirection: 'column' }}>
          <div className="row" style={{ padding: '16px', borderBottom: '1px solid var(--surface-3)', flexShrink: 0 }}>
            <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 18 }}>Team Chat</span>
            <span className="spacer" />
            <button className="btn ghost xs" onClick={() => setShowNewGroup(true)}>+ Group</button>
          </div>

          {error && <div className="error" style={{ margin: 8 }}>{error}</div>}

          <div style={{ flex: 1, overflowY: 'auto' }}>
            {loadingGroups && (
              <div style={{ padding: 12 }}>
                {[...Array(4)].map((_, i) => <div key={i} className="shimmer" style={{ height: 52, borderRadius: 6, marginBottom: 8 }} />)}
              </div>
            )}
            {!loadingGroups && groups.length === 0 && (
              <div className="empty" style={{ padding: 20 }}>No groups yet. Create one.</div>
            )}
            {groups.map((g) => (
              <div
                key={g.id}
                onClick={() => selectGroup(g)}
                style={{
                  padding: '12px 16px',
                  cursor: 'pointer',
                  background: selectedGroup?.id === g.id ? 'rgba(255,98,0,0.1)' : 'transparent',
                  borderLeft: selectedGroup?.id === g.id ? '3px solid var(--orange)' : '3px solid transparent',
                  borderBottom: '1px solid var(--surface-3)',
                }}
              >
                <div className="row" style={{ gap: 10 }}>
                  <div className="avatar avatar-sm" style={{ background: 'var(--surface-3)' }}>{(g.name || 'G')[0].toUpperCase()}</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 600, fontSize: 14 }} className="truncate">{g.name}</div>
                    {g.lastMessage && (
                      <div className="muted text-sm truncate">{g.lastMessage.body || ''}</div>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Main */}
        <div className="chat-main" style={{ display: 'flex', flexDirection: 'column' }}>
          {!selectedGroup ? (
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div className="empty">Select a group to start chatting</div>
            </div>
          ) : (
            <>
              {/* Header */}
              <div style={{ padding: '14px 20px', borderBottom: '1px solid var(--surface-3)', flexShrink: 0 }}>
                <div style={{ fontWeight: 700, fontSize: 16 }}>{selectedGroup.name}</div>
              </div>

              {/* Messages */}
              <div className="chat-messages" style={{ flex: 1, overflowY: 'auto', padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: 12 }}>
                {loadingMessages && [...Array(4)].map((_, i) => (
                  <div key={i} className="shimmer" style={{ height: 50, borderRadius: 8, width: `${50 + Math.random() * 30}%` }} />
                ))}
                {!loadingMessages && messages.length === 0 && (
                  <div className="empty">No messages yet. Say hello!</div>
                )}
                {messages.map((msg: any, i: number) => {
                  const mine = isMyMessage(msg);
                  return (
                    <div key={msg.id || i} className={`chat-msg${mine ? ' mine' : ''}`} style={{ display: 'flex', flexDirection: 'column', alignItems: mine ? 'flex-end' : 'flex-start' }}>
                      {!mine && (
                        <div className="row" style={{ gap: 6, marginBottom: 4 }}>
                          <div className="avatar avatar-sm">{initials(msg.user?.name || msg.senderName || '?')}</div>
                          <span className="muted text-sm">{msg.user?.name || msg.senderName || 'Team'}</span>
                        </div>
                      )}
                      <div className="chat-bubble" style={{
                        padding: '10px 14px',
                        borderRadius: mine ? '16px 16px 4px 16px' : '16px 16px 16px 4px',
                        background: mine ? 'var(--orange)' : 'var(--surface-3)',
                        color: mine ? '#000' : 'var(--film)',
                        maxWidth: '70%',
                        fontSize: 14,
                        lineHeight: 1.5,
                      }}>
                        {msg.body || msg.content || msg.message || ''}
                      </div>
                      <div className="muted" style={{ fontSize: 10, marginTop: 2 }}>{fmtTime(msg.createdAt || msg.sent_at)}</div>
                    </div>
                  );
                })}
                <div ref={messagesEndRef} />
              </div>

              {/* Input */}
              <form onSubmit={sendMessage} style={{ padding: '12px 20px', borderTop: '1px solid var(--surface-3)', flexShrink: 0 }}>
                <div className="row" style={{ gap: 10 }}>
                  <input
                    className="field"
                    style={{ flex: 1 }}
                    placeholder="Type a message..."
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    disabled={sending}
                  />
                  <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }} disabled={sending || !message.trim()}>
                    {sending ? '...' : 'Send'}
                  </button>
                </div>
              </form>
            </>
          )}
        </div>
      </div>

      {/* New Group Modal */}
      {showNewGroup && (
        <div className="modal-backdrop" onClick={() => setShowNewGroup(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 380 }}>
            <div className="row" style={{ marginBottom: 16 }}>
              <span style={{ fontFamily: 'Bebas Neue, sans-serif', fontSize: 20 }}>New Group</span>
              <span className="spacer" />
              <button className="btn ghost xs" onClick={() => setShowNewGroup(false)}>×</button>
            </div>
            {groupErr && <div className="error" style={{ marginBottom: 10 }}>{groupErr}</div>}
            <form onSubmit={createGroup}>
              <div className="field" style={{ marginBottom: 16 }}>
                <label>Group Name *</label>
                <input className="field" required value={groupName} onChange={(e) => setGroupName(e.target.value)} placeholder="e.g. Editing Team" autoFocus />
              </div>
              <div className="row" style={{ gap: 10, justifyContent: 'flex-end' }}>
                <button type="button" className="btn ghost" onClick={() => setShowNewGroup(false)}>Cancel</button>
                <button type="submit" className="btn" style={{ background: 'var(--orange)', color: '#000' }}>Create</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AppShell>
  );
}
