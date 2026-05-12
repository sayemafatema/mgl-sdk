import { createNativeStackNavigator } from '@react-navigation/native-stack';
import HomeScreen from '../screens/HomeScreen';
import LoginScreen from '../screens/LoginScreen';
import ProfileScreen from '../screens/ProfileScreen';
import ChangePinScreen from '../screens/ChangePinScreen';
import ReceiptScreen from '../screens/ReceiptScreen';
import ScanScreen from '../screens/ScanScreen';

export type ReceiptRouteParams = {
  stationName: string;
  vehicleRegNo: string;
  amountDisplay: string;
  serverTxnId?: string;
};

export type RootStackParamList = {
  Login: undefined;
  Home: undefined;
  Profile: undefined;
  ChangePin: undefined;
  Scan: undefined;
  Receipt: ReceiptRouteParams;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function RootNavigator() {
  return (
    <Stack.Navigator initialRouteName="Login">
      <Stack.Screen name="Login" component={LoginScreen} options={{ title: 'Login' }} />
      <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'Home' }} />
      <Stack.Screen name="Profile" component={ProfileScreen} options={{ title: 'Profile' }} />
      <Stack.Screen name="ChangePin" component={ChangePinScreen} options={{ title: 'Change PIN' }} />
      <Stack.Screen name="Scan" component={ScanScreen} options={{ title: 'Scan & Pay' }} />
      <Stack.Screen name="Receipt" component={ReceiptScreen} options={{ title: 'Fueling Complete' }} />
    </Stack.Navigator>
  );
}

