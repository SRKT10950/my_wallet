import React, { useState } from 'react';
import { Box, Card, CardContent, Typography, Button, TextField, InputAdornment, Chip, IconButton, Dialog, DialogTitle, DialogContent, DialogActions } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import LanguageIcon from '@mui/icons-material/Language';
import StoreIcon from '@mui/icons-material/Store';
import DescriptionIcon from '@mui/icons-material/Description';
import DeleteIcon from '@mui/icons-material/Delete';
import MenuBookIcon from '@mui/icons-material/MenuBook';
import DeleteForeverIcon from '@mui/icons-material/DeleteForever';
import AddIcon from '@mui/icons-material/Add';
import CheckIcon from '@mui/icons-material/Check';
import { Product } from '../types';
import { MASTER_PRODUCT_CATALOG } from '../data/masterProductCatalog';

interface ProductMasterProps {
  products: Product[];
  onAddProduct: (p: Product) => void;
  onUpdateProduct: (p: Product) => void;
  onDeleteProduct: (id: number) => void;
  onDeleteAllProducts?: () => void;
  onOpenWebSearch: (initialQuery?: string) => void;
}

export const ProductMaster: React.FC<ProductMasterProps> = ({
  products,
  onAddProduct,
  onUpdateProduct,
  onDeleteProduct,
  onDeleteAllProducts,
  onOpenWebSearch
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [isCatalogOpen, setIsCatalogOpen] = useState(false);
  const [catalogSearch, setCatalogSearch] = useState('');
  const [catalogCategory, setCatalogCategory] = useState('All');

  const categories = ['All', ...Array.from(new Set(products.map(p => p.category))).sort()];

  const filteredProducts = products.filter(p => {
    const matchesCat = selectedCategory === 'All' || p.category === selectedCategory;
    if (!searchQuery.trim()) return matchesCat;
    const q = searchQuery.toLowerCase();
    return matchesCat && (
      p.productName.toLowerCase().includes(q) ||
      (p.localName && p.localName.toLowerCase().includes(q)) ||
      p.category.toLowerCase().includes(q) ||
      (p.appName && p.appName.toLowerCase().includes(q)) ||
      (p.description && p.description.toLowerCase().includes(q))
    );
  });

  const catalogFiltered = MASTER_PRODUCT_CATALOG.filter(p => {
    const matchesCat = catalogCategory === 'All' || p.category.toLowerCase() === catalogCategory.toLowerCase();
    if (!catalogSearch.trim()) return matchesCat;
    const q = catalogSearch.toLowerCase();
    return matchesCat && (
      p.productName.toLowerCase().includes(q) ||
      (p.localName && p.localName.toLowerCase().includes(q)) ||
      p.category.toLowerCase().includes(q)
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

          <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap' }}>
            <Button variant="outlined" color="primary" startIcon={<MenuBookIcon />} onClick={() => setIsCatalogOpen(true)}>
              Browse Master Catalog
            </Button>
            <Button variant="contained" color="primary" startIcon={<LanguageIcon />} onClick={() => onOpenWebSearch(searchQuery)}>
              Search Web / Google Products
            </Button>
            {onDeleteAllProducts && products.length > 0 && (
              <Button variant="outlined" color="error" startIcon={<DeleteForeverIcon />} onClick={() => {
                if (window.confirm('Are you sure you want to delete ALL products from database?')) {
                  onDeleteAllProducts();
                }
              }}>
                Delete All Products
              </Button>
            )}
          </Box>
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

      {/* Empty State */}
      {filteredProducts.length === 0 && (
        <Card sx={{ padding: 4, textAlign: 'center' }}>
          <Typography variant="h6" color="text.secondary" sx={{ mb: 1.5 }}>
            No Products in Database
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
            Your product catalog is currently empty. You can browse the Master Catalog (Vegetables, Fruits, Groceries, Medicines, Personal Care) or search web products to manually add items.
          </Typography>
          <Box sx={{ display: 'flex', justifyContent: 'center', gap: 2 }}>
            <Button variant="contained" color="primary" startIcon={<MenuBookIcon />} onClick={() => setIsCatalogOpen(true)}>
              Browse Master Catalog
            </Button>
            <Button variant="outlined" color="primary" startIcon={<LanguageIcon />} onClick={() => onOpenWebSearch('')}>
              Search Web Products
            </Button>
          </Box>
        </Card>
      )}

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
              <Typography variant="caption" color="text.secondary">Date: {p.priceDate || new Date().toISOString().split('T')[0]}</Typography>
              <IconButton size="small" color="error" onClick={() => p.id && onDeleteProduct(p.id)}>
                <DeleteIcon sx={{ fontSize: 18 }} />
              </IconButton>
            </Box>
          </Card>
        ))}
      </Box>

      {/* Master Catalog Dialog */}
      <Dialog open={isCatalogOpen} onClose={() => setIsCatalogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle sx={{ fontWeight: 800, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 800 }}>📚 Master Product Catalog</Typography>
            <Typography variant="caption" color="primary">Vegetables, Fruits, Groceries, Medicines, Personal Care</Typography>
          </Box>
        </DialogTitle>
        <DialogContent dividers>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <Box sx={{ display: 'flex', gap: 1, overflowX: 'auto', pb: 0.5 }}>
              {['All', 'Vegetables', 'Fruits', 'Groceries', 'Medicines', 'Personal Care'].map(cat => (
                <Chip
                  key={cat}
                  label={cat}
                  onClick={() => setCatalogCategory(cat)}
                  color={catalogCategory === cat ? 'primary' : 'default'}
                  variant={catalogCategory === cat ? 'filled' : 'outlined'}
                  sx={{ fontWeight: 700 }}
                />
              ))}
            </Box>
            <TextField
              size="small"
              placeholder="Search catalog (e.g. Mango, Potato, KitKat, Sugar)..."
              value={catalogSearch}
              onChange={(e) => setCatalogSearch(e.target.value)}
              slotProps={{
                input: {
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchIcon color="primary" />
                    </InputAdornment>
                  )
                }
              }}
            />
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1, maxHeight: 400, overflowY: 'auto' }}>
              {catalogFiltered.map((item, idx) => {
                const isAlreadyInDb = products.some(p => p.productName.toLowerCase() === item.productName.toLowerCase());
                return (
                  <Box key={idx} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', p: 1.5, borderRadius: 2, background: 'rgba(255, 255, 255, 0.04)', border: '1px solid rgba(255, 255, 255, 0.08)' }}>
                    <Box>
                      <Typography variant="subtitle2" sx={{ fontWeight: 800, color: '#FFF' }}>{item.productName}</Typography>
                      {item.localName && <Typography variant="caption" sx={{ color: 'warning.main', fontWeight: 700, display: 'block' }}>{item.localName}</Typography>}
                      <Typography variant="caption" color="text.secondary">🏷️ {item.category} • ₹{item.currentPrice} / {item.quantity} {item.unit}</Typography>
                    </Box>
                    <Button
                      size="small"
                      variant={isAlreadyInDb ? 'outlined' : 'contained'}
                      color={isAlreadyInDb ? 'inherit' : 'primary'}
                      disabled={isAlreadyInDb}
                      startIcon={isAlreadyInDb ? <CheckIcon /> : <AddIcon />}
                      onClick={() => {
                        onAddProduct({
                          ...item,
                          id: Date.now() + Math.floor(Math.random() * 1000),
                          priceDate: new Date().toISOString().split('T')[0]
                        });
                      }}
                    >
                      {isAlreadyInDb ? 'Added' : 'Add'}
                    </Button>
                  </Box>
                );
              })}
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setIsCatalogOpen(false)} color="primary">Done</Button>
        </DialogActions>
      </Dialog>

    </Box>
  );
};
