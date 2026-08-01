import React, { useState } from 'react';
import { Box, Card, CardContent, Typography, Button, TextField, InputAdornment, Chip, IconButton } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import LanguageIcon from '@mui/icons-material/Language';
import StoreIcon from '@mui/icons-material/Store';
import DescriptionIcon from '@mui/icons-material/Description';
import DeleteIcon from '@mui/icons-material/Delete';
import { Product } from '../types';

interface ProductMasterProps {
  products: Product[];
  onAddProduct: (p: Product) => void;
  onUpdateProduct: (p: Product) => void;
  onDeleteProduct: (id: number) => void;
  onOpenWebSearch: (initialQuery?: string) => void;
}

export const ProductMaster: React.FC<ProductMasterProps> = ({
  products,
  onAddProduct,
  onUpdateProduct,
  onDeleteProduct,
  onOpenWebSearch
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');

  const categories = ['All', ...Array.from(new Set(products.map(p => p.category))).sort()];

  const filteredProducts = products.filter(p => {
    const matchesCat = selectedCategory === 'All' || p.category === selectedCategory;
    if (!searchQuery.trim()) return matchesCat;
    const q = searchQuery.toLowerCase();
    return matchesCat && (
      p.productName.toLowerCase().includes(q) ||
      p.localName.toLowerCase().includes(q) ||
      p.category.toLowerCase().includes(q) ||
      p.appName.toLowerCase().includes(q) ||
      p.description.toLowerCase().includes(q)
    );
  });

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
      
      {/* Header Bar */}
      <Card>
        <CardContent sx={{ padding: 2.5, display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 2 }}>
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800, color: '#FFF' }}>Product Master / Catalog</Typography>
            <Typography variant="caption" color="primary" sx={{ fontWeight: 700 }}>
              {products.filter(p => p.active).length} Active Products in Database
            </Typography>
          </Box>

          <Button variant="contained" color="primary" startIcon={<LanguageIcon />} onClick={() => onOpenWebSearch(searchQuery)}>
            Search Web / Google Products
          </Button>
        </CardContent>
      </Card>

      {/* Search & Category Filter */}
      <Card>
        <CardContent sx={{ padding: 2 }}>
          <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'center', flexWrap: 'wrap' }}>
            <TextField
              fullWidth
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search product by name, local name, or description..."
              slotProps={{
                input: {
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchIcon color="primary" />
                    </InputAdornment>
                  )
                }
              }}
              size="small"
              sx={{ flex: 1, minWidth: 260 }}
            />

            {searchQuery.trim() && (
              <Button variant="outlined" color="secondary" startIcon={<LanguageIcon />} onClick={() => onOpenWebSearch(searchQuery)}>
                Search Web for "{searchQuery}"
              </Button>
            )}
          </Box>

          {/* Category Chips */}
          <Box sx={{ display: 'flex', gap: 1, overflowX: 'auto', pt: 1.5, pb: 0.5 }}>
            {categories.map((cat) => (
              <Chip
                key={cat}
                label={cat}
                onClick={() => setSelectedCategory(cat)}
                color={selectedCategory === cat ? 'primary' : 'default'}
                variant={selectedCategory === cat ? 'filled' : 'outlined'}
                sx={{ fontWeight: 700, borderRadius: 2 }}
              />
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* Product Cards Grid */}
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 2 }}>
        {filteredProducts.map((p) => (
          <Card key={p.id} sx={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
            <CardContent sx={{ padding: 2 }}>
              
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
                <Box>
                  <Typography variant="subtitle1" sx={{ fontWeight: 800, color: '#FFF' }}>{p.productName}</Typography>
                  {p.localName && (
                    <Typography variant="caption" sx={{ color: 'warning.main', fontWeight: 700, display: 'block' }}>
                      {p.localName}
                    </Typography>
                  )}
                </Box>
                <Chip label={`₹${p.currentPrice} / ${p.quantity} ${p.unit}`} color="primary" size="small" sx={{ fontWeight: 800 }} />
              </Box>

              <Box sx={{ display: 'flex', gap: 1, alignItems: 'center', mb: 1 }}>
                <Chip label={p.category} size="small" color="secondary" sx={{ height: 20, fontSize: 10, fontWeight: 700 }} />
                {p.appName && (
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                    <StoreIcon sx={{ fontSize: 14 }} /> {p.appName}
                  </Typography>
                )}
              </Box>

              {/* Lowercase DB Field description Display */}
              {p.description && (
                <Box sx={{ background: 'rgba(255, 255, 255, 0.04)', borderRadius: 2, padding: 1.2, border: '1px solid rgba(255, 255, 255, 0.08)', display: 'flex', gap: 1, mt: 1 }}>
                  <DescriptionIcon color="primary" sx={{ fontSize: 16, mt: 0.2 }} />
                  <Typography variant="caption" color="text.secondary" sx={{ lineHeight: 1.4 }}>
                    <strong style={{ color: '#FFF' }}>Description:</strong> {p.description}
                  </Typography>
                </Box>
              )}

            </CardContent>

            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingX: 2, paddingBottom: 1.5, borderTop: '1px solid rgba(255, 255, 255, 0.08)', pt: 1 }}>
              <Typography variant="caption" color="text.secondary">Date: {p.priceDate}</Typography>
              <IconButton size="small" color="error" onClick={() => p.id && onDeleteProduct(p.id)}>
                <DeleteIcon sx={{ fontSize: 18 }} />
              </IconButton>
            </Box>
          </Card>
        ))}
      </Box>

    </Box>
  );
};
