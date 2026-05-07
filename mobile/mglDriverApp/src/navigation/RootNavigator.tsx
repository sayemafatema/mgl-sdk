import { createNativeStackNavigator } from '@react-navigation/native-stack';
import HomeScreen from '../screens/HomeScreen';
import LoginScreen from '../screens/LoginScreen';
import ReceiptScreen from '../screens/ReceiptScreen';
import ScanScreen from '../screens/ScanScreen';

export type RootStackParamList = {
  Login: undefined;
  Home: undefined;
  Scan: undefined;
  Receipt: { receiptText: string };
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function RootNavigator() {
  return (
    <Stack.Navigator initialRouteName="Login">
      <Stack.Screen name="Login" component={LoginScreen} options={{ title: 'Login' }} />
      <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Home' }} />
      <Stack.Screen name="Scan" component={ScanScreen} options={{ title: 'Scan' }} />
      <Stack.Screen name="Receipt" component={ReceiptScreen} options={{ title: 'Receipt' }} />
    </Stack.Navigator>
  );
}

