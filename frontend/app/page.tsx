import { WalletInfo } from '@/components/WalletInfo';
import { TokenBalance } from '@/components/TokenBalance';

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-50">
      <WalletInfo />
      <div className="max-w-4xl mx-auto px-8 py-6">
        <TokenBalance />
      </div>
    </div>
  )
}
