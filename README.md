# cohort_analysis

## Keterangan :

### pandas dan numpy adalah library yang digunakan dalam praktek kali ini
### Data.csv adalah data yang kita upload
### data.head() adalah bahasa untuk menampilkan 5 data teratas
### Item daftar

import pandas as pd
import numpy as np

### pd.read_csv() adalah perintah untuk membaca file,
### engine program yang kita gunakan yaitu menggunakan python
### encoding adalah

data = pd.read_csv('data.csv', engine='python', encoding='ISO-8859-1')
data.head()

### fungsi .head() adalah untuk melihat 5 data teratas

# Reformat Timestamp
### Riformat timestamp diperlukan dalam pembuatan cohort analysis karena data yang diambil biasanya tersedial dalam format waktu yang lebih detail seperti bulanan, mingguan atau bahkan harian.

### Jika data dalam format waktu ini tidak diformat, maka akan sulit untuk mengelompokkan pengguna ke dalam cohort berdasarkan bulan atau minggu tertentu, yang merupakan bagian penting dari analisis cohort

### Dengan reformat timestamp, kita dapat merubah data waktu yang awalnya berupa informasi timestamp menjadi informasi bulan atau minggu, dan kemudian kita dapat mengelompokkan pengguna berdasarkan bulan atau minggu tertentu di mana mereka bergabung dengan produk atau layanan

import dateutil
from datetime import datetime as dt
from pytz import utc

data['datetime'] = data['InvoiceDate'].apply(lambda x: dateutil.parser.parse(x).timestamp())
data['month'] = data['datetime'].apply(lambda x: dt.fromtimestamp(x, utc).month)
data['year'] = data['datetime'].apply(lambda x: dt.fromtimestamp(x, utc).year)

data.head()

# Membuat Cohort

#### merubah 'AUG 2010'
#### menjadi '2010 Aug'
#### AUG 2010 -> 201008

data['cohort'] = data.apply(lambda row: (row['year'] * 100) + (row['month']), axis=1)

#### 2010 * 100 = 201000
#### AUG -> 201000 + 08 = 201008

cohort = data.groupby('CustomerID')['cohort'].min().reset_index()
cohort.columns = ['CustomerID', 'first_cohort']
data = data.merge(cohort, on='CustomerID', how='left')

data.head()

# Membuat header cohort

### Mengapa perlu menggunakna header? membuat header untuk setiap cohort dalam codingan Python pada analisis cohort analisis berguna untuk memberikan konteks dan informasi yang lebih jelas tentang cohort yang sedang dianalisis.

### informasi pada header

### periode waktu / kategori cohort tertentu yang sedang di analisis
### ukuran sampel
### rentang usia
### jenis kelamin cohort yang sedangn di analaisis
### informasi yang ada pada header dapat memudahkan kita dalam memahami hasil analisis yang ditamilkan dan membuat bisnis yang lebih tepat berdasarkan hasil analisis

headers = data['cohort'].value_counts().reset_index()

headers.columns = ['cohort', 'count']

headers.head()

headers = headers.sort_values(['cohort'])['cohort'].to_list()

headers

### Dalam cohort analisis, pivot table dapat digunakan untuk membandingkan perilaku pelanggan antar cohort.

### contoh:

### membandingkan persentase pelanggan yang melakukan pembelian ulang di setiap cohort
### membandingkan rata rata jumlah pembelian di setiap cohort
### dengan melakukan pivot data, informasi yang relevan dapa dikelompokkan dan dibandingkan, sehingga dapat memberikan wawasan lebih dalam tentang kinerja bisnis di setiap cohort

data.dropna(inplace=True)
data['cohort_distance'] = data.apply(lambda row: (headers.index(row['cohort']) - headers.index(row['first_cohort'])) if (row['first_cohort'] != 0 and row['cohort'] != 0) else np.nan, axis=1)

data.head()

### Baris kode tersebut merupakan implementasi dari bagian yang terkait dengan perhitungan jarak atau selisih antara tanggal bergabung pertama (first_cohort) dengan tanggal bergabung kembali (cohort).

### fungsinya adalah untuk menambahkan kolom baru bernama 'cohort_distance' pada dataset, di mana setiap barisnya akan dihitun dengan rumus yang ada di dalam fungsi lambda. Jarak antar dua tanggal tersebut dihitung berdasarkan posisi kolom dari tanggal cohort dan tanggal first_cohort di dalam dataset

cohort_pivot = pd.pivot_table(data, index='first_cohort', columns='cohort_distance', values='CustomerID', aggfunc=pd.Series.nunique)
cohort_pivot

### index='firs_cohort' : menjadikan kolom first_cohort sebagai index pada pivot table
### columns='cohort_distance': menjadikan kolom cohort_distance sebagai kolom pada pivot table
### values='CustomerID': nilai pada pivot table diisi dengan jumlah CustomerID yang termasuk ke dalam masing masing kolom cohort_distance dan index first_cohort
### aggfunc=pd.Series.nunique: menjumlahkan CustomerID yang unik pada setiap sel dalam pivot table

cohort_pivot = cohort_pivot.div(cohort_pivot[0], axis=0)
cohort_pivot

### pada syntax tersebut, cohort_pivot dihasilkan dari pivot table yang telah dibuat sebelumnya. kemudian dilakukan normalisasi nilai pada setiap kolom dengan menggunakan nilai pada kolom pertama (kolom dengan index 0) sebagai pembagi, yaitu cohort_pivot[0].

### Tujuannya adalah untuk memperoleh nilai persentase dari jumlah customer yang masih aktif pada setiap peridoe berdasarkan jumlah customer yang bergabung pada periode awal. Dengan kata lain, dilakukan perbandingan jumlah customer yang bergabung pada periode awal.

import seaborn as sns
import matplotlib.pyplot as plt

fig_dims = (12, 8)

fig, ax = plt.subplots(figsize=fig_dims)

sns.heatmap(cohort_pivot, annot=True, fmt='.0%', mask=cohort_pivot.isnull(), ax=ax, square=True, linewidths=.5, cmap=sns.cubehelix_palette(8))

plt.show()

