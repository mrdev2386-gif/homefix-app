import { db } from './firebase';
import { collection, getDocs, addDoc, serverTimestamp } from 'firebase/firestore';

const defaultBanners = [
    {
        title: 'Deep Home Cleaning',
        description: 'Get your home sparkling clean with our professional deep cleaning services.',
        imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6954?auto=format&fit=crop&q=80',
        isActive: true,
        order: 0
    },
    {
        title: 'AC Service & Repair',
        description: 'Expert AC maintenance and repair to keep you cool all summer long.',
        imageUrl: 'https://images.unsplash.com/photo-1621905252507-b354bcadc0e2?auto=format&fit=crop&q=80',
        isActive: true,
        order: 1
    },
    {
        title: 'Professional Painting',
        description: 'Transform your living space with our top-rated painting professionals.',
        imageUrl: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80',
        isActive: true,
        order: 2
    }
];

export async function initializeBanners() {
    const bannerCol = collection(db, 'service_bottom_banners');
    const snapshot = await getDocs(bannerCol);

    if (snapshot.empty) {
        console.log('Initializing default banners...');
        for (const banner of defaultBanners) {
            await addDoc(bannerCol, {
                ...banner,
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp()
            });
        }
    }
}
