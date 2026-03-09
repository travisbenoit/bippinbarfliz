import { User } from 'lucide-react';

interface Transaction {
  id: string;
  from_user_id: string;
  to_user_id: string;
  amount: number;
  transaction_type: string;
  description: string | null;
  drink_name: string | null;
  created_at: string;
  from_user?: {
    name: string;
    avatar_url: string | null;
  };
  to_user?: {
    name: string;
    avatar_url: string | null;
  };
}

interface TransactionHistoryProps {
  transactions: Transaction[];
  currentUserId?: string;
}

export function TransactionHistory({ transactions, currentUserId }: TransactionHistoryProps) {
  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
  };

  const formatDate = (timestamp: string) => {
    const date = new Date(timestamp);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (date.toDateString() === today.toDateString()) {
      return 'Today';
    } else if (date.toDateString() === yesterday.toDateString()) {
      return 'Yesterday';
    }
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const groupTransactionsByDate = (transactions: Transaction[]) => {
    const groups: { [key: string]: Transaction[] } = {};

    transactions.forEach(transaction => {
      const dateKey = formatDate(transaction.created_at);
      if (!groups[dateKey]) {
        groups[dateKey] = [];
      }
      groups[dateKey].push(transaction);
    });

    return groups;
  };

  const groupedTransactions = groupTransactionsByDate(transactions);

  return (
    <div className="space-y-6">
      {Object.entries(groupedTransactions).map(([date, dateTransactions]) => (
        <div key={date}>
          <h3 className="text-sm font-semibold text-gray-500 mb-3">{date}</h3>
          <div className="space-y-3">
            {dateTransactions.map((transaction) => {
              const isReceived = transaction.to_user_id === currentUserId;
              const otherUser = isReceived ? transaction.from_user : transaction.to_user;
              const amount = Number(transaction.amount);

              return (
                <div
                  key={transaction.id}
                  className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0"
                >
                  <div className="flex items-center space-x-3">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-purple-400 to-purple-600 flex items-center justify-center overflow-hidden">
                      {otherUser?.avatar_url ? (
                        <img
                          src={otherUser.avatar_url}
                          alt={otherUser.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <User className="w-6 h-6 text-white" />
                      )}
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900">
                        {otherUser?.name || 'Unknown User'}
                      </p>
                      <p className="text-sm text-gray-500">
                        {formatTime(transaction.created_at)}
                      </p>
                    </div>
                  </div>
                  <div
                    className={`font-bold text-lg ${
                      isReceived ? 'text-green-600' : 'text-red-500'
                    }`}
                  >
                    {isReceived ? '+' : '-'}${amount.toFixed(0)}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}
