'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount, useBalance, useChainId, useSwitchChain } from 'wagmi';
import { formatEther } from 'viem';
import { mainnet, sepolia, polygon, arbitrum } from 'wagmi/chains';

export function WalletInfo() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { chains, switchChain } = useSwitchChain();
  
  const { data: balance } = useBalance({
    address: address,
  });

  const getChainName = (id: number) => {
    const chainMap: Record<number, string> = {
      1: 'Ethereum',
      11155111: 'Sepolia',
      137: 'Polygon',
      42161: 'Arbitrum',
    };
    return chainMap[id] || `Chain ${id}`;
  };

  if (!isConnected) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen gap-4">
        <h1 className="text-4xl font-bold">SwapStarter</h1>
        <p className="text-gray-600">Connect your wallet to get started</p>
        <ConnectButton />
      </div>
    );
  }

  return (
    <div className="p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold">SwapStarter</h1>
          <ConnectButton />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Wallet Address Card */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-sm text-gray-500 mb-2">Wallet Address</h3>
            <p className="font-mono text-sm break-all">{address}</p>
          </div>

          {/* Network Card */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-sm text-gray-500 mb-2">Current Network</h3>
            <p className="font-semibold">{getChainName(chainId)}</p>
            <div className="mt-4">
              <p className="text-xs text-gray-500 mb-2">Switch Network:</p>
              <div className="flex flex-wrap gap-2">
                {chains.map((chain) => (
                  <button
                    key={chain.id}
                    onClick={() => switchChain({ chainId: chain.id })}
                    className={`px-3 py-1 rounded text-xs ${
                      chainId === chain.id
                        ? 'bg-blue-500 text-white'
                        : 'bg-gray-200 hover:bg-gray-300'
                    }`}
                    disabled={chainId === chain.id}
                  >
                    {chain.name}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Balance Card */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-sm text-gray-500 mb-2">Balance</h3>
            <p className="text-2xl font-bold">
              {balance ? parseFloat(formatEther(balance.value)).toFixed(4) : '0.0000'}
            </p>
            <p className="text-sm text-gray-500">{balance?.symbol || 'ETH'}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
