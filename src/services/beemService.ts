export interface BeemUser {
  username: string;
  linkedAt: string;
}

export async function linkBeemAccount(username: string): Promise<boolean> {
  try {
    if (!username.trim()) {
      return false;
    }

    const response = await fetch('https://www.beem.com.au/api/verify-user', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ username }),
    });

    return response.ok;
  } catch (error) {
    console.error('Failed to link Beem account:', error);
    return false;
  }
}

export async function sendBeemPayment(
  recipientUsername: string,
  amount: number,
  description?: string
): Promise<boolean> {
  try {
    const response = await fetch('https://www.beem.com.au/api/send', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${import.meta.env.VITE_BEEM_API_KEY || ''}`,
      },
      body: JSON.stringify({
        recipient: recipientUsername,
        amount,
        description,
      }),
    });

    return response.ok;
  } catch (error) {
    console.error('Failed to send Beem payment:', error);
    return false;
  }
}

export async function requestBeemPayment(
  senderUsername: string,
  amount: number,
  description?: string
): Promise<boolean> {
  try {
    const response = await fetch('https://www.beem.com.au/api/request', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${import.meta.env.VITE_BEEM_API_KEY || ''}`,
      },
      body: JSON.stringify({
        sender: senderUsername,
        amount,
        description,
      }),
    });

    return response.ok;
  } catch (error) {
    console.error('Failed to request Beem payment:', error);
    return false;
  }
}
