import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import App from '../App';

// Mock fetch globally
global.fetch = jest.fn();

beforeEach(() => {
  fetch.mockClear();
});

describe('App Component', () => {
  it('renders header with app title', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => [],
    });

    render(<App />);
    expect(screen.getByText('DevOps Project')).toBeInTheDocument();
  });

  it('shows loading state initially', () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => [],
    });

    render(<App />);
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  it('renders items fetched from backend', async () => {
    const mockItems = [
      { id: 1, name: 'Item Alpha' },
      { id: 2, name: 'Item Beta' },
    ];

    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => mockItems,
    });

    render(<App />);

    expect(await screen.findByText('Item Alpha')).toBeInTheDocument();
    expect(await screen.findByText('Item Beta')).toBeInTheDocument();
  });

  it('shows error message when fetch fails', async () => {
    fetch.mockRejectedValueOnce(new Error('Network error'));

    render(<App />);

    await waitFor(() => {
      expect(screen.getByRole('alert')).toBeInTheDocument();
    });
  });

  it('shows empty state when no items', async () => {
    fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => [],
    });

    render(<App />);

    await waitFor(() => {
      expect(screen.getByText('No items found.')).toBeInTheDocument();
    });
  });

  it('can add a new item', async () => {
    const initialItems = [{ id: 1, name: 'Item Alpha' }];
    const updatedItems = [
      { id: 1, name: 'Item Alpha' },
      { id: 2, name: 'New Item' },
    ];

    fetch
      .mockResolvedValueOnce({ ok: true, json: async () => initialItems })
      .mockResolvedValueOnce({ ok: true, json: async () => ({}) })
      .mockResolvedValueOnce({ ok: true, json: async () => updatedItems });

    render(<App />);

    await screen.findByText('Item Alpha');

    const input = screen.getByPlaceholderText('Enter item name...');
    fireEvent.change(input, { target: { value: 'New Item' } });
    fireEvent.click(screen.getByText('Add Item'));

    await waitFor(() => {
      expect(screen.getByText('New Item')).toBeInTheDocument();
    });
  });
});
